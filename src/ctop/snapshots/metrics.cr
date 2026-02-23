# Combined snapshot of all system metrics
record Ctop::Snapshots::Metrics,
  cpu : Ctop::Snapshots::CPU,
  memory : Ctop::Snapshots::Memory,
  net : Ctop::Snapshots::Net,
  proc : Ctop::Snapshots::Proc
