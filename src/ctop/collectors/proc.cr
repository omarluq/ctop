# Collects process information with CPU usage tracking.
#
# ```
# proc = Ctop::Collectors::Proc.new
# sleep 1 # Allow baseline to establish
# snapshot = proc.collect
# snapshot.processes.first(10).each do |p|
#   puts "#{p.name}: #{p.cpu_percent.round(1)}% CPU, #{p.memory_kb / 1024} MB"
# end
# ```
class Ctop::Collectors::Proc < Ctop::Collectors::Base(Ctop::Snapshots::Proc)
  # Track PID stats for cpu_usage! calculations across calls
  @pid_stats : Hash(Int64, Hardware::PID::Stat) = {} of Int64 => Hardware::PID::Stat
  @cpu : Hardware::CPU

  def initialize
    @cpu = Hardware::CPU.new
  end

  # Collect process list, sorted by CPU usage (default limit 100).
  def collect : Ctop::Snapshots::Proc
    collect(100)
  end

  # Collect with custom limit on number of processes returned.
  def collect(limit : Int32) : Ctop::Snapshots::Proc
    processes = [] of Ctop::Snapshots::ProcessInfo
    current_pids = Set(Int64).new

    # Iterate over all PIDs, handling race conditions where processes exit
    begin
      Hardware::PID.each do |pid|
        current_pids << pid.number
        info = collect_process_info(pid)
        processes << info if info
      end
    rescue Hardware::Error
      # Process exited during iteration - continue with what we have
    end

    # Clean up stats for dead processes
    @pid_stats.reject! { |k, _| !current_pids.includes?(k) }

    # Sort by CPU usage descending
    processes.sort_by!(&.cpu_percent)
    processes.reverse!

    Ctop::Snapshots::Proc.new(
      processes: processes.first(limit),
      total_count: processes.size
    )
  end

  private def collect_process_info(pid : Hardware::PID) : Ctop::Snapshots::ProcessInfo?
    # Get or create stat tracker for this PID
    stat = @pid_stats[pid.number]? || pid.stat(@cpu)
    @pid_stats[pid.number] = stat

    Ctop::Snapshots::ProcessInfo.new(
      pid: pid.number,
      name: pid.name,
      state: stat.state,
      cpu_percent: stat.cpu_usage!,
      memory_kb: pid.memory,
      command: pid.command
    )
  rescue
    # Process may have exited between iteration and access
    nil
  end
end
