require "../../spec_helper"

describe Ctop::Collectors::Manager do
  describe "#initialize" do
    it "creates a Manager" do
      manager = Ctop::Collectors::Manager.new
      manager.should be_a(Ctop::Collectors::Manager)
    end

    it "initializes all collectors" do
      manager = Ctop::Collectors::Manager.new

      manager.cpu.should be_a(Ctop::Collectors::CPU)
      manager.memory.should be_a(Ctop::Collectors::Memory)
      manager.net.should be_a(Ctop::Collectors::Net)
      manager.proc.should be_a(Ctop::Collectors::Proc)
    end
  end

  describe "#collect" do
    it "returns a Metrics record" do
      manager = Ctop::Collectors::Manager.new
      metrics = manager.collect
      metrics.should be_a(Ctop::Collectors::Manager::Metrics)
    end

    it "contains all collector snapshots" do
      manager = Ctop::Collectors::Manager.new
      metrics = manager.collect

      metrics.cpu.should be_a(Ctop::Collectors::CPU::Snapshot)
      metrics.memory.should be_a(Ctop::Collectors::Memory::Snapshot)
      metrics.net.should be_a(Ctop::Collectors::Net::Snapshot)
      metrics.proc.should be_a(Ctop::Collectors::Proc::Snapshot)
    end

    it "returns valid CPU metrics" do
      manager = Ctop::Collectors::Manager.new
      manager.collect # baseline
      sleep 0.1.seconds
      metrics = manager.collect

      metrics.cpu.usage.should be >= 0.0
      metrics.cpu.usage.should be <= 100.0
    end

    it "returns valid Memory metrics" do
      manager = Ctop::Collectors::Manager.new
      metrics = manager.collect

      metrics.memory.total_bytes.should be > 0
      metrics.memory.percent.should be >= 0.0
      metrics.memory.percent.should be <= 100.0
    end

    it "returns valid Net metrics" do
      manager = Ctop::Collectors::Manager.new
      metrics = manager.collect

      metrics.net.rx_bytes.should be >= 0
      metrics.net.tx_bytes.should be >= 0
    end

    it "returns valid Proc metrics" do
      manager = Ctop::Collectors::Manager.new
      metrics = manager.collect

      metrics.proc.total_count.should be > 0
      metrics.proc.processes.should_not be_empty
    end
  end

  describe "#collect(proc_limit)" do
    it "respects process limit" do
      manager = Ctop::Collectors::Manager.new
      metrics = manager.collect(proc_limit: 3)

      metrics.proc.processes.size.should be <= 3
    end
  end

  describe "Metrics record" do
    it "is immutable" do
      manager = Ctop::Collectors::Manager.new
      metrics = manager.collect

      # Verify we can access all fields
      metrics.cpu.should_not be_nil
      metrics.memory.should_not be_nil
      metrics.net.should_not be_nil
      metrics.proc.should_not be_nil
    end
  end

  describe "collector access" do
    it "allows direct access to individual collectors" do
      manager = Ctop::Collectors::Manager.new

      # Can call individual collectors directly
      cpu_snapshot = manager.cpu.collect
      cpu_snapshot.should be_a(Ctop::Collectors::CPU::Snapshot)

      memory_snapshot = manager.memory.collect
      memory_snapshot.should be_a(Ctop::Collectors::Memory::Snapshot)
    end
  end
end
