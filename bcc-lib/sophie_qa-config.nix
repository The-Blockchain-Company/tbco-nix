##########################################################
###############         Sophie QA         ###############
############### Bcc Node Configuration ###############
##########################################################

{
  ##### Locations #####

  ColeGenesisFile = ./sophie_qa + "/cole-genesis.json";
  ColeGenesisHash = "9325495d3ac7554d4bfaf2392cc3c74676d5add873d6ef8862d7562e660940bf";
  SophieGenesisFile = ./sophie_qa + "/sophie-genesis.json";
  SophieGenesisHash = "85d1783750753deaa6560158eb85fcb30078ea32a36e12dd8af39168bc053d09";
  AurumGenesisFile = ./sophie_qa + "/aurum-genesis.json";
  AurumGenesisHash = "fd77bbad445e6c438e2755d5e939a818d5d231316f882c7725988ebfac8442f8";

  ##### Core protocol parameters #####

  # This is the instance of the Shardagnostic family that we are running.
  # The node also supports various test and mock instances.
  # "RealPBFT" is the real (ie not mock) (permissive) OBFT protocol, which
  # is what we use on mainnet in Cole era.
  Protocol = "Bcc";

  PBftSignatureThreshold = 0.9;
  # The mainnet does not include the network magic into addresses. Testnets do.
  RequiresNetworkMagic = "RequiresMagic";

  TestSophieHardForkAtEpoch = 2;

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
