##########################################################
###############          Testnet           ###############
############### Bcc Node Configuration ###############
##########################################################

{
  ##### Locations #####

  ColeGenesisFile = ./testnet + "/cole-genesis.json";
  ColeGenesisHash = "96fceff972c2c06bd3bb5243c39215333be6d56aaf4823073dca31afe5038471";
  SophieGenesisFile = ./testnet + "/sophie-genesis.json";
  SophieGenesisHash = "849a1764f152e1b09c89c0dfdbcbdd38d711d1fec2db5dfa0f87cf2737a0eaf4";
  AurumGenesisFile = ./testnet + "/aurum-genesis.json";
  AurumGenesisHash = "7e94a15f55d1e82d10f09203fa1d40f8eede58fd8066542cf6566008068ed874";


  ##### Core protocol parameters #####

  # This is the instance of the Shardagnostic family that we are running.
  # The node also supports various test and mock instances.
  # "RealPBFT" is the real (ie not mock) (permissive) OBFT protocol, which
  # is what we use on mainnet in Cole era.
  Protocol = "Bcc";

  # The mainnet does not include the network magic into addresses. Testnets do.
  RequiresNetworkMagic = "RequiresMagic";

  MaxKnownMajorProtocolVersion = 2;

  ##### Update system parameters #####

  # This protocol version number gets used by block producing nodes as part
  # part of the system for agreeing on and synchronising protocol updates.
  LastKnownBlockVersion-Major = 3;
  LastKnownBlockVersion-Sentry = 0;

  # In the Cole era some software versions are also published on the chain.
  # We do this only for Cole compatibility now.
  ApplicationName = "bcc-sl";
  ApplicationVersion = 0;
}
