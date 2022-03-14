##########################################################
###############          Mainnet           ###############
############### Bcc Node Configuration ###############
##########################################################

{
  ##### Locations #####

  ColeGenesisFile = ./mainnet + "/cole-genesis.json";
  ColeGenesisHash = "5f20df933584822601f9e3f8c024eb5eb252fe8cefb24d1317dc3d432e940ebb";
  SophieGenesisFile = ./mainnet + "/sophie-genesis.json";
  SophieGenesisHash = "1a3be38bcbb7911969283716ad7aa550250226b76a61fc51cc9a9a35d9276d81";
  AurumGenesisFile = ./mainnet + "/aurum-genesis.json";
  AurumGenesisHash = "7e94a15f55d1e82d10f09203fa1d40f8eede58fd8066542cf6566008068ed874";


  ##### Core protocol parameters #####

  # This is the instance of the Shardagnostic family that we are running.
  # The node also supports various test and mock instances.
  # "RealPBFT" is the real (ie not mock) (permissive) OBFT protocol, which
  # is what we use on mainnet in Cole era.
  Protocol = "Bcc";

  # The mainnet does not include the network magic into addresses. Testnets do.
  RequiresNetworkMagic = "RequiresNoMagic";

  MaxKnownMajorProtocolVersion = 2;

  ##### Update system parameters #####

  # This protocol version number gets used by block producing nodes as part
  # part of the system for agreeing on and synchronising protocol updates.
  LastKnownBlockVersion-Major = 3;
  LastKnownBlockVersion-Minor = 0;
  LastKnownBlockVersion-Alt = 0;

  # In the Cole era some software versions are also published on the chain.
  # We do this only for Cole compatibility now.
  ApplicationName = "bcc-sl";
  ApplicationVersion = 1;
}
