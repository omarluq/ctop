require "hardware"

# Information about a single process
record Ctop::Snapshots::ProcessInfo,
  pid : Int64,
  name : String,
  state : Hardware::PID::Stat::State,
  cpu_percent : Float64,
  memory_kb : Int32,
  command : String

# Immutable snapshot of process list
record Ctop::Snapshots::Proc,
  processes : Array(Ctop::Snapshots::ProcessInfo), # Sorted by CPU usage descending
  total_count : Int32                              # Total number of processes
