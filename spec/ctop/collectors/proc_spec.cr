require "../../spec_helper"

describe Ctop::Collectors::Proc do
  describe "#initialize" do
    it "creates a Proc collector" do
      proc = Ctop::Collectors::Proc.new
      proc.should be_a(Ctop::Collectors::Proc)
    end
  end

  describe "#collect" do
    it "returns a Snapshot" do
      proc = Ctop::Collectors::Proc.new
      snapshot = proc.collect
      snapshot.should be_a(Ctop::Collectors::Proc::Snapshot)
    end

    it "returns processes array" do
      proc = Ctop::Collectors::Proc.new
      snapshot = proc.collect
      snapshot.processes.should be_a(Array(Ctop::Collectors::Proc::ProcessInfo))
    end

    it "returns positive total_count" do
      proc = Ctop::Collectors::Proc.new
      snapshot = proc.collect
      snapshot.total_count.should be > 0
    end

    it "respects limit parameter" do
      proc = Ctop::Collectors::Proc.new
      snapshot = proc.collect(limit: 5)
      snapshot.processes.size.should be <= 5
    end

    it "includes current process" do
      proc = Ctop::Collectors::Proc.new
      snapshot = proc.collect
      current_pid = Process.pid.to_i64

      pids = snapshot.processes.map(&.pid)
      pids.should contain(current_pid)
    end

    it "sorts processes by CPU usage descending" do
      proc = Ctop::Collectors::Proc.new
      proc.collect # baseline
      sleep 0.1.seconds
      snapshot = proc.collect

      if snapshot.processes.size > 1
        cpu_values = snapshot.processes.map(&.cpu_percent)
        cpu_values.should eq(cpu_values.dup.sort!.reverse!)
      end
    end
  end

  describe "ProcessInfo" do
    it "contains expected fields" do
      proc = Ctop::Collectors::Proc.new
      snapshot = proc.collect

      info = snapshot.processes.first
      info.pid.should be > 0
      info.name.should_not be_empty
      info.cpu_percent.should be >= 0.0
      info.memory_kb.should be >= 0
    end

    it "has valid state" do
      proc = Ctop::Collectors::Proc.new
      snapshot = proc.collect

      snapshot.processes.each do |info|
        info.state.should be_a(Hardware::PID::Stat::State)
      end
    end
  end

  describe "Snapshot" do
    it "is immutable (record)" do
      info = Ctop::Collectors::Proc::ProcessInfo.new(
        pid: 1234_i64,
        name: "test",
        state: Hardware::PID::Stat::State::Running,
        cpu_percent: 5.0,
        memory_kb: 1024,
        command: "/usr/bin/test"
      )

      snapshot = Ctop::Collectors::Proc::Snapshot.new(
        processes: [info],
        total_count: 1
      )

      snapshot.processes.size.should eq(1)
      snapshot.total_count.should eq(1)
    end
  end

  describe "ProcessInfo record" do
    it "supports equality comparison" do
      p1 = Ctop::Collectors::Proc::ProcessInfo.new(
        pid: 1234_i64, name: "test",
        state: Hardware::PID::Stat::State::Running,
        cpu_percent: 5.0, memory_kb: 1024,
        command: "/usr/bin/test"
      )
      p2 = Ctop::Collectors::Proc::ProcessInfo.new(
        pid: 1234_i64, name: "test",
        state: Hardware::PID::Stat::State::Running,
        cpu_percent: 5.0, memory_kb: 1024,
        command: "/usr/bin/test"
      )
      p3 = Ctop::Collectors::Proc::ProcessInfo.new(
        pid: 5678_i64, name: "other",
        state: Hardware::PID::Stat::State::Running,
        cpu_percent: 5.0, memory_kb: 1024,
        command: "/usr/bin/other"
      )

      p1.should eq(p2)
      p1.should_not eq(p3)
    end
  end
end
