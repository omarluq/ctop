# Unified manager for all system metric collectors.
#
# Bundles CPU, Memory, Network, and Process collectors and provides
# a single `collect` method that returns all metrics at once.
#
# Designed to be called on timer tick events in the main event loop:
#
# ```
# termisu = Termisu.new
# termisu.enable_timer(1.second)
# collectors = Ctop::Collectors::Manager.new
#
# termisu.each_event do |event|
#   case event
#   when Termisu::Event::Tick
#     metrics = collectors.collect
#     # Update panels with metrics.cpu, metrics.memory, etc.
#     termisu.render
#   when Termisu::Event::Key
#     break if event.ctrl_c?
#   end
# end
# ```
class Ctop::Collectors::Manager
  getter cpu : CPU
  getter memory : Memory
  getter net : Net
  getter proc : Proc

  # Combined snapshot of all system metrics
  record Metrics,
    cpu : CPU::Snapshot,
    memory : Memory::Snapshot,
    net : Net::Snapshot,
    proc : Proc::Snapshot

  def initialize
    @cpu = CPU.new
    @memory = Memory.new
    @net = Net.new
    @proc = Proc.new
  end

  # Collect all system metrics at once.
  #
  # Returns a Metrics record containing snapshots from all collectors.
  # Call this on each timer tick to refresh the UI.
  def collect : Metrics
    Metrics.new(
      cpu: @cpu.collect,
      memory: @memory.collect,
      net: @net.collect,
      proc: @proc.collect
    )
  end

  # Collect with custom process limit.
  def collect(proc_limit : Int32) : Metrics
    Metrics.new(
      cpu: @cpu.collect,
      memory: @memory.collect,
      net: @net.collect,
      proc: @proc.collect(proc_limit)
    )
  end
end
