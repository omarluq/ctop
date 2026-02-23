# Immutable snapshot of CPU metrics
record Ctop::Snapshots::CPU,
  usage : Float64,          # Total CPU usage 0-100%
  per_core : Array(Float64) # Per-core usage 0-100% (currently zeros due to hardware lib bug)
