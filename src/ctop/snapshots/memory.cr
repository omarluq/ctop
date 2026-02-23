# Immutable snapshot of memory metrics (all sizes in bytes)
record Ctop::Snapshots::Memory,
  total_bytes : Int64,     # Total physical memory
  used_bytes : Int64,      # Memory in use
  available_bytes : Int64, # Memory available for allocation
  percent : Float64        # Usage percentage 0-100
