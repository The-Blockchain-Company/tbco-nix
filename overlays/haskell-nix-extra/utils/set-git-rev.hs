{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Stamps a Haskell executable with a git revision.
-- The target executable must have use "Data.FileEmbed.dummySpace".
--
-- This progam is originally from bcc-sl.

module Main where

import           Control.DeepSeq (force)
import           Control.Exception (ErrorCall (..), handle, evaluate)
import           Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B8
import           Data.FileEmbed (injectWith)
import           Data.List (isInfixOf)
import           System.Exit (die, exitFailure, exitSuccess)
import           System.Environment (getArgs)

main :: IO ()
main = do
  (hash, progs) <- parseArgs
  mapM_ (setGitRev hash) progs

setGitRev :: ByteString -> FilePath -> IO ()
setGitRev hash prog = do
  putStr $ "Setting gitrev of " <> prog <> " ... "
  bs <- B8.readFile prog
  injectWith' "gitrev" hash bs >>= \case
    Right bs' -> do
      B8.writeFile prog bs'
      B8.putStrLn "OK"
      exitSuccess
    Left "" -> do
      B8.putStrLn $ "Failed setting gitrev to \"" <> hash <> "\""
      exitFailure
    Left msg | "Size is: \"\"" `isInfixOf` msg -> do
                 -- Ignore programs without a gitrev injected
                 B8.putStrLn "File does not have dummySpace."
                 exitSuccess
    Left msg -> do
      putStrLn msg
      exitFailure

-- | Work around annoying use of error function in file-embed.
injectWith' :: ByteString -> ByteString -> ByteString -> IO (Either String ByteString)
injectWith' postfix toInj orig = handle (pure . toLeft) (toRight <$> evaluateNF inj)
  where
    inj = injectWith postfix toInj orig
    toRight (Just a) = Right a
    toRight Nothing  = Left ""
    toLeft (ErrorCall msg) = Left msg
    evaluateNF = evaluate . force
    
parseArgs :: IO (ByteString, [FilePath])
parseArgs = getArgs >>= \case
  (rev:prog:progs) -> pure (B8.pack rev, (prog:progs))
  _ -> die "usage: set-git-rev REV PROG [PROGS...]" >> exitFailure
