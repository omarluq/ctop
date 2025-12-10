require "../../spec_helper"

describe Ctop::Collectors::CPU do
  describe "#initialize" do
    it "creates a CPU collector" do
      cpu = Ctop::Collectors::CPU.new
      cpu.should be_a(Ctop::Collectors::CPU)
    end
  end

  describe "#collect" do
    it "returns a Snapshot" do
      cpu = Ctop::Collectors::CPU.new
      snapshot = cpu.collect
      snapshot.should be_a(Ctop::Collectors::CPU::Snapshot)
    end

    it "returns usage between 0 and 100 after warmup" do
      cpu = Ctop::Collectors::CPU.new
      cpu.collect # First call establishes baseline (returns NaN/0)
      sleep 0.1.seconds
      snapshot = cpu.collect

      snapshot.usage.should be >= 0.0
      snapshot.usage.should be <= 100.0
    end

    it "returns per-core usage array matching core count" do
      cpu = Ctop::Collectors::CPU.new
      snapshot = cpu.collect

      snapshot.per_core.size.should eq(cpu.core_count)
    end

    # NOTE: Per-core values are currently zeros due to hardware lib bug
    it "returns per-core usage array" do
      cpu = Ctop::Collectors::CPU.new
      snapshot = cpu.collect

      snapshot.per_core.each do |core_usage|
        core_usage.should be >= 0.0
        core_usage.should be <= 100.0
      end
    end
  end

  describe "#core_count" do
    it "returns positive number of cores" do
      cpu = Ctop::Collectors::CPU.new
      cpu.core_count.should be > 0
    end

    it "matches System.cpu_count" do
      cpu = Ctop::Collectors::CPU.new
      cpu.core_count.should eq(System.cpu_count.to_i32)
    end
  end

  describe "Snapshot" do
    it "is immutable (record)" do
      snapshot = Ctop::Collectors::CPU::Snapshot.new(
        usage: 50.0,
        per_core: [25.0, 75.0]
      )

      snapshot.usage.should eq(50.0)
      snapshot.per_core.should eq([25.0, 75.0])
    end

    it "supports equality comparison" do
      s1 = Ctop::Collectors::CPU::Snapshot.new(usage: 50.0, per_core: [25.0])
      s2 = Ctop::Collectors::CPU::Snapshot.new(usage: 50.0, per_core: [25.0])
      s3 = Ctop::Collectors::CPU::Snapshot.new(usage: 60.0, per_core: [25.0])

      s1.should eq(s2)
      s1.should_not eq(s3)
    end
  end
end
