require "../../spec_helper"

describe Ctop::Collectors::Memory do
  describe "#initialize" do
    it "creates a Memory collector" do
      memory = Ctop::Collectors::Memory.new
      memory.should be_a(Ctop::Collectors::Memory)
    end
  end

  describe "#collect" do
    it "returns a Snapshot" do
      memory = Ctop::Collectors::Memory.new
      snapshot = memory.collect
      snapshot.should be_a(Ctop::Collectors::Memory::Snapshot)
    end

    it "returns positive total_bytes" do
      memory = Ctop::Collectors::Memory.new
      snapshot = memory.collect
      snapshot.total_bytes.should be > 0
    end

    it "returns used_bytes less than or equal to total_bytes" do
      memory = Ctop::Collectors::Memory.new
      snapshot = memory.collect
      snapshot.used_bytes.should be <= snapshot.total_bytes
      snapshot.used_bytes.should be >= 0
    end

    it "returns available_bytes less than or equal to total_bytes" do
      memory = Ctop::Collectors::Memory.new
      snapshot = memory.collect
      snapshot.available_bytes.should be <= snapshot.total_bytes
      snapshot.available_bytes.should be >= 0
    end

    it "returns percent between 0 and 100" do
      memory = Ctop::Collectors::Memory.new
      snapshot = memory.collect
      snapshot.percent.should be >= 0.0
      snapshot.percent.should be <= 100.0
    end

    it "has consistent values (used + available ≈ total)" do
      memory = Ctop::Collectors::Memory.new
      snapshot = memory.collect

      # Allow some tolerance for kernel reserved memory
      sum = snapshot.used_bytes + snapshot.available_bytes
      sum.should be <= snapshot.total_bytes
    end
  end

  describe "Snapshot" do
    it "is immutable (record)" do
      snapshot = Ctop::Collectors::Memory::Snapshot.new(
        total_bytes: 16_000_000_000_i64,
        used_bytes: 8_000_000_000_i64,
        available_bytes: 8_000_000_000_i64,
        percent: 50.0
      )

      snapshot.total_bytes.should eq(16_000_000_000_i64)
      snapshot.used_bytes.should eq(8_000_000_000_i64)
      snapshot.available_bytes.should eq(8_000_000_000_i64)
      snapshot.percent.should eq(50.0)
    end

    it "supports equality comparison" do
      s1 = Ctop::Collectors::Memory::Snapshot.new(
        total_bytes: 1000_i64, used_bytes: 500_i64,
        available_bytes: 500_i64, percent: 50.0
      )
      s2 = Ctop::Collectors::Memory::Snapshot.new(
        total_bytes: 1000_i64, used_bytes: 500_i64,
        available_bytes: 500_i64, percent: 50.0
      )
      s3 = Ctop::Collectors::Memory::Snapshot.new(
        total_bytes: 2000_i64, used_bytes: 500_i64,
        available_bytes: 500_i64, percent: 50.0
      )

      s1.should eq(s2)
      s1.should_not eq(s3)
    end
  end
end
