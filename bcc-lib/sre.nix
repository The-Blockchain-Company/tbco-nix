##########################################################
###############            SRE             ###############
############### Bcc Node Configuration ###############
##########################################################

{
  ##### Locations #####

  ColeGenesisFile = ./sre + "/cole-genesis.json";
  ColeGenesisHash = "2322d5dc4b3bab5b18cbcbfe62b0c29a55c994cc8fee157aad1425fd51cb46bb";
  SophieGenesisFile = ./sre + "/sophie-genesis.json";
  SophieGenesisHash = "bdf17f12d82d89908211f693c30e1cb114fe4b0954159394f08ca043c3446b95";
  AurumGenesisFile = ./sre + "/aurum-genesis.json";
  AurumGenesisHash = "fd77bbad445e6c438e2755d5e939a818d5d231316f882c7725988ebfac8442f8";

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
