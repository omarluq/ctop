# Collects memory usage metrics.
#
# ```
# memory = Ctop::Collectors::Memory.new
# snapshot = memory.collect
# puts "Used: #{snapshot.used_bytes / 1024 / 1024} MB"
# puts "Percent: #{snapshot.percent.round(1)}%"
# ```
class Ctop::Collectors::Memory < Ctop::Collectors::Base
  # Immutable snapshot of memory metrics (all sizes in bytes)
  record Snapshot,
    total_bytes : Int64,     # Total physical memory
    used_bytes : Int64,      # Memory in use
    available_bytes : Int64, # Memory available for allocation
    percent : Float64        # Usage percentage 0-100

  # Collect current memory state
  def collect : Snapshot
    hw = Hardware::Memory.new
    Snapshot.new(
      total_bytes: hw.total.to_i64 * 1024,
      used_bytes: hw.used.to_i64 * 1024,
      available_bytes: hw.available.to_i64 * 1024,
      percent: hw.percent
    )
  end
end
