##########################################################
###############         P2P Testnet        ###############
############### Bcc Node Configuration ###############
##########################################################

{
  ##### Locations #####

  ColeGenesisFile = ./p2p + "/cole-genesis.json";
  ColeGenesisHash = "414e27b56b4b147e40bd95cc5552a2c97043c04e3de8b4c7ea5fc90fce25a68e";
  SophieGenesisFile = ./p2p + "/sophie-genesis.json";
  SophieGenesisHash = "a0e8e5520ab7c452c4e36020ded12c791a10abd7ca25c083af6149fe269ddb67";
  AurumGenesisFile = ./p2p + "/aurum-genesis.json";
  AurumGenesisHash = "7e94a15f55d1e82d10f09203fa1d40f8eede58fd8066542cf6566008068ed874";

  ##### Core protocol parameters #####

  # This is the instance of the Shardagnostic family that we are running.
  # The node also supports various test and mock instances.
  # "RealPBFT" is the real (ie not mock) (permissive) OBFT protocol, which
  # is what we use on mainnet in Cole era.
  Protocol = "Bcc";

  PBftSignatureThreshold = 1.1;
  # The mainnet does not include the network magic into addresses. Testnets do.
  RequiresNetworkMagic = "RequiresMagic";

  TestSophieHardForkAtEpoch = 1;
  TestEvieHardForkAtEpoch = 2;
  TestJenHardForkAtEpoch = 3;
  TestAurumHardForkAtEpoch = 4;

  ### P2P

  EnableP2P = true;
  TestEnableDevelopmentNetworkProtocols = true;
  TraceInboundGovernorCounters = true;

  MaxKnownMajorProtocolVersion = 2;
  #### LOGGING Debug

  minSeverity = "Debug";

  ##### Update system parameters #####

  # This protocol version number gets used by block producing nodes as part
  # part of the system for agreeing on and synchronising protocol updates.
  LastKnownBlockVersion-Major = 3;
  LastKnownBlockVersion-Sentry = 1;

  # In the Cole era some software versions are also published on the chain.
  # We do this only for Cole compatibility now.
  ApplicationName = "bcc-sl";
  ApplicationVersion = 0;
}
