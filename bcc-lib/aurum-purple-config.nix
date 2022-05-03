##########################################################
###############    Aurum Purple Testnet   ###############
############### Bcc Node Configuration ###############
##########################################################

{
  ##### Locations #####

  ColeGenesisFile = ./aurum-purple + "/cole-genesis.json";
  ColeGenesisHash = "570b0e27e60daa224088e0d3afce5dce98b62f6280c21b9074797ef61eab64b2";
  SophieGenesisFile = ./aurum-purple + "/sophie-genesis.json";
  SophieGenesisHash = "733960b0b305cbfedcca13d2fea87b077f17501d257d4d2844d1f1e3d9dea0b7";
  AurumGenesisFile = ./aurum-purple + "/aurum-genesis.json";
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

  TestEnableDevelopmentHardForkEras = false;
  TestEnableDevelopmentNetworkProtocols = false;

  MaxKnownMajorProtocolVersion = 5;
  #### LOGGING Debug

  minSeverity = "Debug";

  ##### Update system parameters #####

  # This protocol version number gets used by block producing nodes as part
  # part of the system for agreeing on and synchronising protocol updates.
  LastKnownBlockVersion-Major = 5;
  LastKnownBlockVersion-Sentry = 1;

  # In the Cole era some software versions are also published on the chain.
  # We do this only for Cole compatibility now.
  ApplicationName = "bcc-sl";
  ApplicationVersion = 0;
}
