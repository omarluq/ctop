# Collects CPU usage metrics for total and per-core.
#
# ```
# cpu = Ctop::Collectors::CPU.new
# loop do
#   sleep 1
#   snapshot = cpu.collect
#   puts "Total: #{snapshot.usage.round(1)}%"
#   snapshot.per_core.each_with_index { |u, i| puts "Core #{i}: #{u.round(1)}%" }
# end
# ```
#
# NOTE: Per-core stats currently return zero due to a parsing bug in the
# hardware library. Total CPU usage works correctly.
class Ctop::Collectors::CPU < Ctop::Collectors::Base(Ctop::Snapshots::CPU)
  @hw_cpu : Hardware::CPU

  def initialize
    @hw_cpu = Hardware::CPU.new
  end

  # Collect current CPU usage. First call establishes baseline.
  def collect : Ctop::Snapshots::CPU
    # Per-core CPU parsing is broken in hardware lib (breaks too early)
    # For now, return zeros for per_core and use total CPU only
    Ctop::Snapshots::CPU.new(
      usage: @hw_cpu.usage!,
      per_core: Array.new(core_count, 0.0)
    )
  end

  # Number of CPU cores
  def core_count : Int32
    System.cpu_count.to_i32
  end
end
