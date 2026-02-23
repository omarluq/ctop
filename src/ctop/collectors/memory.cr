# Collects memory usage metrics.
#
# ```
# memory = Ctop::Collectors::Memory.new
# snapshot = memory.collect
# puts "Used: #{snapshot.used_bytes / 1024 / 1024} MB"
# puts "Percent: #{snapshot.percent.round(1)}%"
# ```
class Ctop::Collectors::Memory < Ctop::Collectors::Base(Ctop::Snapshots::Memory)
  # Collect current memory state
  def collect : Ctop::Snapshots::Memory
    hw = Hardware::Memory.new
    Ctop::Snapshots::Memory.new(
      total_bytes: hw.total.to_i64 * 1024,
      used_bytes: hw.used.to_i64 * 1024,
      available_bytes: hw.available.to_i64 * 1024,
      percent: hw.percent
    )
  end
end
