{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- |
-- Copyright: © 2018-2022 TBCO
-- License: Apache-2.0
--
-- Functions for building projects with Stack under Buildkite.

module CommonBuild
  (
  -- * Re-export
    module Turtle
  , module Prelude
  -- * Build directory
  , setupBuildDirectory
  , cleanBuildDirectory
  -- * Buildkite
  , BuildkiteEnv(..)
  , getBuildkiteEnv
  , onDefaultBranch
  , isBorsBuild
  -- * Weeder
  , weederStep
  -- * Coverage
  , CoverallsConfig (CoverallsConfig, NoCoverallsConfig)
  , CoverallsTokenEnvVar (CoverallsTokenEnvVar)
  , ExtraShcArgs (ExtraShcArgs)
  , ExtraTixFilesDirectory (ExtraTixFilesDirectory)
  , uploadCoverageStep
  , findTix
  -- * Stack caching
  , CICacheConfig(..)
  , getCacheConfig
  , cacheGetStep
  , cachePutStep
  , cleanupCacheStep
  , purgeCacheStep
  -- * Running stuff
  , DryRun(..)
  , run
  , whenRun
  , whenRun'
  -- * Utils
  , needRead
  , want
  , timeout
  , doMaybe
  ) where

import Prelude hiding
    ( FilePath )

import Options.Applicative
import Turtle hiding
    ( arg, match, opt, option, skip )

import Control.Concurrent.Async
    ( race )
import Control.Exception
    ( IOException, catch )
import Control.Monad
    ( filterM, forM_ )
import Control.Monad.Extra
    ( whenM )
import Control.Monad.Trans.Class
    ( lift )
import Control.Monad.Trans.Maybe
    ( MaybeT (..) )
import Data.ByteString
    ( ByteString )
import Data.Char
    ( isSpace )
import Data.Maybe
    ( mapMaybe, maybeToList )
import Safe
    ( headMay, readMay )

import qualified Control.Foldl as Fold
import qualified Data.ByteString.Char8 as B8
import qualified Data.Text as T
import qualified Filesystem.Path.CurrentOS as FP
import qualified Turtle.Bytes as TB

data DryRun = Run | DryRun deriving (Show, Eq)

-- | Stack with caching needs a build directory that is the same across
-- all BuildKite agents. The build directory option can be used to
-- ensure this is the case.
setupBuildDirectory :: DryRun -> FilePath -> IO ()
setupBuildDirectory dryRun buildDir = do
    removeDirectory dryRun buildDir
    src <- pwd
    printf ("Copying source tree "%fp%" -> "%fp%"\n") src buildDir
    whenRun dryRun $ do
        cptree src buildDir
        cd buildDir

-- | Remove certain files which get cached but could cause problems for subsequent
-- builds.
cleanBuildDirectory :: FilePath -> IO ()
cleanBuildDirectory buildDir = findTix buildDir >>= mapM_ rm

----------------------------------------------------------------------------
-- Buildkite
-- https://buildkite.com/docs/pipelines/environment-variables

-- | A selection of relevant pipeline and build information from Buildkite.
data BuildkiteEnv = BuildkiteEnv
    { bkBuildNum      :: Int
    -- ^ The Buildkite build number.
    , bkPipeline      :: Text
    -- ^ The pipeline slug on Buildkite as used in URLs.
    , bkBranch        :: Text
    -- ^ The branch being built.
    , bkBaseBranch    :: Maybe Text
    -- ^ The base branch that the pull request is targeting, if this
    -- build is for a pull request.
    , bkDefaultBranch :: Text
    -- ^ The default branch for the pipeline (e.g. master).
    , bkTag           :: Maybe Text
    -- ^ The name of the tag being built, if this build was triggered from a tag.
    } deriving (Show)

-- | Fetch build parameters from the environment.
getBuildkiteEnv :: IO (Maybe BuildkiteEnv)
getBuildkiteEnv = runMaybeT $ do
    bkBuildNum      <- MaybeT $ needRead "BUILDKITE_BUILD_NUMBER"
    bkPipeline      <- MaybeT $ need "BUILDKITE_PIPELINE_SLUG"
    bkBranch        <- MaybeT $ need "BUILDKITE_BRANCH"
    bkBaseBranch    <- lift   $ want "BUILDKITE_PULL_REQUEST_BASE_BRANCH"
    bkDefaultBranch <- MaybeT $ need "BUILDKITE_PIPELINE_DEFAULT_BRANCH"
    bkTag           <- lift   $ want "BUILDKITE_TAG"
    pure BuildkiteEnv {..}

-- | Whether we are building the repo's default branch.
onDefaultBranch :: BuildkiteEnv -> Bool
onDefaultBranch BuildkiteEnv{..} = bkBranch == bkDefaultBranch

-- | Whether we are building for Bors, based on the branch name.
isBorsBuild :: BuildkiteEnv -> Bool
isBorsBuild bk = "bors/" `T.isPrefixOf` bkBranch bk

----------------------------------------------------------------------------
-- Weeder - uses contents of .stack-work to determine unused dependencies

weederStep :: DryRun -> IO ExitCode
weederStep dryRun = do
    echo "--- Weeder"
    run dryRun "weeder" []

----------------------------------------------------------------------------
-- Stack Haskell Program Coverage and upload to Coveralls

-- | Name of the environment variable containing the coveralls.io token, which
-- is used for uploading coverage information to coveralls.io.
--
-- If coverage information shouldn't be uploaded, or such token is not
-- available, then the string can be set to "".
newtype CoverallsTokenEnvVar = CoverallsTokenEnvVar Text deriving (Show)

-- | Extra arguments to be passed to the @shc@ program, which provides
-- coveralls.io integration to @stack@ based projects.
newtype ExtraShcArgs = ExtraShcArgs [Text] deriving (Show)

-- | Where to look for extra @.tix@ files.
--
-- Under normal circumstances, the coverage files (@.tix@) can be found in:
--
-- > stack path --local-hpc-root
--
-- which is basically what shc uses under the hood. However there might be
-- extra @.tix@ files, possibly generated by executables built with the
-- @--coverage@ flag, and ran as part of the test suite of another package.
-- Thus, this option allows to specify the directory where to (recursively)
-- look for extra @.tix@ files.
--
-- FIXME: it should be possible to figure out what are the roots of each package
-- in the project from a @stack.yaml@ or @cabal.project@ file. In this case
-- this option can be removed.
newtype ExtraTixFilesDirectory = ExtraTixFilesDirectory FilePath deriving (Show)

data CoverallsConfig
  = CoverallsConfig CoverallsTokenEnvVar ExtraShcArgs ExtraTixFilesDirectory
  | NoCoverallsConfig
  deriving (Show)

-- | Upload coverage information to coveralls.
uploadCoverageStep
  :: CoverallsConfig
  -> DryRun
  -> IO ()
uploadCoverageStep NoCoverallsConfig _ = pure ()
uploadCoverageStep
  (CoverallsConfig
    (CoverallsTokenEnvVar tokenVar)
    (ExtraShcArgs extraShcArgs)
    (ExtraTixFilesDirectory tixDir)
  )
  dryRun
  = do
    echo "--- Upload Test Coverage"
    need tokenVar >>= \case
        Nothing -> do
            eprintf ("Environment variable "%s%" not set.\n") tokenVar
            eprintf "Not uploading coverage information.\n"
        Just repoToken ->
            (findTix tixDir >>= generate) .&&. upload repoToken >>= \case
                ExitSuccess -> echo "Coverage information upload successful."
                ExitFailure _ -> echo "Coverage information upload failed."
  where
    generate tixFiles = run dryRun "stack"
        ([ "hpc"
        , "report"
        , "--all"
        ] ++ map (format fp) tixFiles)
    upload repoToken = do
        let shcArgs = extraShcArgs ++ ["combined", "custom"]
        logCommand "shc" shcArgs
        whenRun' dryRun ExitSuccess $
            proc "shc" (["--repo-token", repoToken] ++ shcArgs) empty

findTix :: FilePath -> IO [FilePath]
findTix dir = fold (find (suffix ".tix") dir) Fold.list

----------------------------------------------------------------------------
-- Stack root and .stack-work caching.
--
-- This will only operate when the @STACK_ROOT@ environment variable is set.
--
-- It also needs to be running under Buildkite with a project cache location
-- supplied.

-- | Information required for caching the stack root and @.stack-work@
-- directories.
data CICacheConfig = CICacheConfig
    { ccCacheDir  :: FilePath
    -- ^ Per-project directory to store cache files.
    , ccStackRoot :: FilePath
    -- ^ Absolute location of the @.stack@ directory.
    , ccBranches  :: [Text]
    -- ^ A list of branches to source caches from. The branches will be tried in
    -- order until one is found. When saving caches, the first branch in the list
    -- is used.
    } deriving (Show)

-- | Sets up the 'CICacheConfig' info, or provides a reason why caching can't be
-- done.
getCacheConfig :: Maybe BuildkiteEnv -> Maybe FilePath -> IO (Either Text CICacheConfig)
getCacheConfig Nothing _ =
    pure (Left "BUILDKITE_* environment variables are not set")
getCacheConfig _ Nothing =
    pure (Left "--cache-dir argument was not provided")
getCacheConfig (Just bk) (Just ccCacheDir) =
    (fmap FP.fromText <$> need "STACK_ROOT") >>= \case
        Just ccStackRoot ->
            pure (Right CICacheConfig{ccBranches=cacheBranches bk,..})
        Nothing ->
            pure (Left "STACK_ROOT environment variable is not set")

-- | Create the list of branches to source caches from.
--   1. Build branch;
--   2. PR base branch;
--   3. Repo default branch.
cacheBranches :: BuildkiteEnv -> [Text]
cacheBranches BuildkiteEnv{..} =
    [bkBranch] ++ maybeToList bkBaseBranch ++ [bkDefaultBranch]

cacheGetStep :: Either Text CICacheConfig -> IO ()
cacheGetStep cacheConfig = do
    echo "--- CI Cache Restore"
    case cacheConfig of
        Right cfg -> restoreCICache cfg `catch` \(ex :: IOException) ->
            eprintf ("Failed to download CI cache: "%w%"\nContinuing anyway...\n") ex
        Left ex ->
            eprintf ("Not using CI cache because "%s%"\n") ex

cachePutStep :: Either Text CICacheConfig -> IO ()
cachePutStep cacheConfig = do
    echo "--- CI Cache Save"
    case cacheConfig of
        Right cfg -> saveCICache cfg `catch` \(ex :: IOException) ->
            eprintf ("Failed to upload CI cache: "%w%"\n") ex
        Left _ ->
            printf "CI cache not configured.\n"

getCacheArchive :: MonadIO io => CICacheConfig -> FilePath -> io (Maybe FilePath)
getCacheArchive CICacheConfig{..} ext = do
    let caches = mapMaybe (getCacheName ccCacheDir) ccBranches
    headMay <$> filterM testfile (map (</> ext) caches)

-- | The cache directory for a given branch name. This filepath always has a
-- trailing slash.
getCacheName :: FilePath -> Text -> Maybe FilePath
getCacheName base branch
    | ".." `T.isInfixOf` branch = Nothing
    | otherwise = Just (base </> FP.fromText branch </> "")

-- | The filename for a given branch and cache name.
putCacheName :: CICacheConfig -> FilePath -> Maybe FilePath
putCacheName CICacheConfig{..} ext =
    (</> ext) <$> getCacheName ccCacheDir (head ccBranches)

restoreCICache :: CICacheConfig -> IO ()
restoreCICache cfg = do
    restoreStackRoot cfg
    restoreStackWork cfg

saveCICache :: CICacheConfig -> IO ()
saveCICache cfg = do
    saveStackRoot cfg
    saveStackWork cfg

stackRootCache :: FilePath
stackRootCache = "stack-root.tar.lz4"

stackWorkCache :: FilePath
stackWorkCache = "stack-work.tar.lz4"

restoreStackRoot :: CICacheConfig -> IO ()
restoreStackRoot cfg@CICacheConfig{..} =
    restoreZippedCache stackRootCache cfg $ \tar -> do
        whenM (testpath ccStackRoot) $ rmtree ccStackRoot
        mktree ccStackRoot
        TB.procs "tar" ["-C", "/", "-x"] tar

restoreStackWork :: CICacheConfig -> IO ()
restoreStackWork cfg =
    restoreZippedCache stackWorkCache cfg (TB.procs "tar" ["-x"])

restoreZippedCache
    :: FilePath
    -> CICacheConfig
    -> (Shell ByteString -> IO ())
    -> IO ()
restoreZippedCache ext cfg act = getCacheArchive cfg ext >>= \case
    Just tarfile -> do
        size <- du tarfile
        printf ("Restoring cache "%fp%" ("%sz%") ... ") tarfile size
        act $ TB.inproc "lz4cat" ["-d"] (TB.input tarfile)
        printf "done.\n"
    Nothing ->
        printf ("No "%fp%" cache found.\n") ext

saveStackRoot :: CICacheConfig -> IO ()
saveStackRoot cfg@CICacheConfig{..} = saveZippedCache stackRootCache cfg tar
  where
    tar = TB.inproc "tar" ["-C", "/", "-c", format fp ccStackRoot] empty

saveStackWork :: CICacheConfig -> IO ()
saveStackWork cfg = saveZippedCache stackWorkCache cfg tar
  where
    nullTerminate = (<> "\0") . B8.pack . encodeString
    dirs = nullTerminate <$> find (ends ".stack-work") "."
    tar = TB.inproc "tar" ["--null", "-T", "-", "-c"] dirs

saveZippedCache :: FilePath -> CICacheConfig -> Shell ByteString -> IO ()
saveZippedCache ext cfg@CICacheConfig{..} tar = case putCacheName cfg ext of
    Just tarfile -> sh $ do
        printf ("Saving cache "%fp%" ... ") tarfile
        mktree (directory tarfile)
        tmp <- using (mktempfile ccCacheDir (format fp ext))
        TB.output tmp $ TB.inproc "lz4cat" ["-z"] tar
        mv tmp tarfile
        du tarfile >>= printf ("wrote "%sz%".\n")
    Nothing -> printf ("Could not determine "%fp%" cache name.\n") ext

cleanupCacheStep :: DryRun -> Either Text CICacheConfig -> Maybe FilePath -> IO ()
cleanupCacheStep dryRun cacheConfig buildDir = do
    echo "--- Cleaning up CI cache"
    case cacheConfig of
        Right CICacheConfig{..} -> do
            whenM (testdir ccCacheDir) $
                getBranches >>= cleanupCache dryRun ccCacheDir
            -- Remove the stack root left by the previous build.
            removeDirectory dryRun ccStackRoot
            -- Remove the build directory left by the previous build.
            doMaybe (removeDirectory dryRun) buildDir
        Left ex ->
            eprintf ("Not cleaning up CI cache because: "%s%"\n") ex

purgeCacheStep :: DryRun -> Either Text CICacheConfig -> Maybe FilePath -> IO ()
purgeCacheStep dryRun cacheConfig buildDir = do
    echo "--- Deleting all CI caches"
    case cacheConfig of
        Right CICacheConfig{..} -> do
            removeDirectory dryRun ccCacheDir
            removeDirectory dryRun ccStackRoot
            doMaybe (removeDirectory dryRun) buildDir
        Left ex ->
            eprintf ("Not purging CI cache because: "%s%"\n") ex

-- | Remove all files and directories that do not belong to an active branch cache.
cleanupCache :: DryRun -> FilePath -> [Text] -> IO ()
cleanupCache dryRun cacheDir activeBranches = do
    let branchCaches = mapMaybe (getCacheName cacheDir) activeBranches
        isCache cf = any (\dir -> format fp cf `T.isPrefixOf` format fp dir)
    files <- fold (lstree cacheDir) (Fold.revList)
    forM_ files $ \cf -> do
        st <- stat cf
        if isDirectory st
            then unless (isCache cf branchCaches) $ do
                printf ("Removing directory "%fp%"\n") cf
                whenRun dryRun $ rmdir cf
            else unless (directory cf `elem` branchCaches) $ do
                printf ("Removing file "%fp%"\n") cf
                whenRun dryRun $ rm cf

removeDirectory :: DryRun -> FilePath -> IO ()
removeDirectory dryRun dir = whenM (testpath dir) $ do
    printf ("Removing directory "%fp%".\n") dir
    whenRun dryRun $ rmtree dir

-- | Ask the origin git remote for its list of branches.
getBranches :: MonadIO io => io [Text]
getBranches =
    T.lines <$> strict (sed branchPat (grep branchPat git))
  where
    remote = "origin"
    git = inproc "git" ["ls-remote", "--heads", remote] empty
    branchPat = plus alphaNum *> spaces1 *> "refs/heads/" *> plus anyChar

----------------------------------------------------------------------------
-- Utils

needRead :: (MonadIO io, Read a) => Text -> io (Maybe a)
needRead v = (>>= readMay) . fmap T.unpack <$> need v

want :: MonadIO io => Text -> io (Maybe Text)
want = fmap (>>= nullToNothing) . need
  where
    nullToNothing "" = Nothing
    nullToNothing a = Just a

doMaybe :: Monad m => (a -> m ()) -> Maybe a -> m ()
doMaybe = maybe (pure ())

run :: MonadIO io => DryRun -> Text -> [Text] -> io ExitCode
run dryRun cmd args = do
    logCommand cmd args
    whenRun' dryRun ExitSuccess $ do
        res <- proc cmd args empty
        case res of
            ExitSuccess ->
                pure ()
            ExitFailure code ->
                eprintf
                    ("error: Command exited with code "%d%"!\nContinuing...\n")
                    code
        pure res

logCommand :: MonadIO io => Text -> [Text] -> io ()
logCommand cmd args = printf (s % " " % s % "\n") cmd args'
  where
    args' = T.unwords $ map quote args
    -- simple quoting, just for logging
    quote arg | T.any isSpace arg = "'" <> arg <> "'"
              | otherwise = arg

-- | Runs an action when not in --dry-run mode.
whenRun :: Applicative m => DryRun -> m a -> m ()
whenRun dry = whenRun' dry () . void

-- | Runs an action when not in --dry-run mode, with alternative return value.
whenRun' :: Applicative m => DryRun -> a -> m a -> m a
whenRun' DryRun a _ = pure a
whenRun' Run _ ma = ma

-- | Run an action, but cancel it if it doesn't complete within the given number
-- of minutes.
timeout :: Int -> IO ExitCode -> IO ExitCode
timeout mins act = race (sleep (fromIntegral mins * 60)) act >>= \case
    Right r ->
        pure r
    Left () -> do
        eprintf ("\nTimed out after "%d%" minutes.\n") mins
        pure (ExitFailure 124)
