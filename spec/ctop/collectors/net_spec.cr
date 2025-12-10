require "../../spec_helper"

describe Ctop::Collectors::Net do
  describe "#initialize" do
    it "creates a Net collector" do
      net = Ctop::Collectors::Net.new
      net.should be_a(Ctop::Collectors::Net)
    end
  end

  describe "#collect" do
    it "returns a Snapshot" do
      net = Ctop::Collectors::Net.new
      snapshot = net.collect
      snapshot.should be_a(Ctop::Collectors::Net::Snapshot)
    end

    it "returns non-negative rx_bytes" do
      net = Ctop::Collectors::Net.new
      snapshot = net.collect
      snapshot.rx_bytes.should be >= 0
    end

    it "returns non-negative tx_bytes" do
      net = Ctop::Collectors::Net.new
      snapshot = net.collect
      snapshot.tx_bytes.should be >= 0
    end

    it "returns zero rates on first collect" do
      net = Ctop::Collectors::Net.new
      snapshot = net.collect

      snapshot.rx_rate.should eq(0.0)
      snapshot.tx_rate.should eq(0.0)
    end

    it "returns non-negative rates after first collect" do
      net = Ctop::Collectors::Net.new
      net.collect
      sleep 0.1.seconds
      snapshot = net.collect

      snapshot.rx_rate.should be >= 0.0
      snapshot.tx_rate.should be >= 0.0
    end

    it "tracks cumulative bytes (non-decreasing)" do
      net = Ctop::Collectors::Net.new
      first = net.collect
      sleep 0.05.seconds
      second = net.collect

      second.rx_bytes.should be >= first.rx_bytes
      second.tx_bytes.should be >= first.tx_bytes
    end
  end

  describe "#reset" do
    it "resets rate calculation state" do
      net = Ctop::Collectors::Net.new

      # Establish baseline and get rates
      net.collect
      sleep 0.05.seconds
      net.collect

      # Reset and verify first collect behavior returns
      net.reset
      snapshot = net.collect

      snapshot.rx_rate.should eq(0.0)
      snapshot.tx_rate.should eq(0.0)
    end
  end

  describe "Snapshot" do
    it "is immutable (record)" do
      snapshot = Ctop::Collectors::Net::Snapshot.new(
        rx_bytes: 1000_i64,
        tx_bytes: 500_i64,
        rx_rate: 100.0,
        tx_rate: 50.0
      )

      snapshot.rx_bytes.should eq(1000_i64)
      snapshot.tx_bytes.should eq(500_i64)
      snapshot.rx_rate.should eq(100.0)
      snapshot.tx_rate.should eq(50.0)
    end

    it "supports equality comparison" do
      s1 = Ctop::Collectors::Net::Snapshot.new(
        rx_bytes: 1000_i64, tx_bytes: 500_i64,
        rx_rate: 100.0, tx_rate: 50.0
      )
      s2 = Ctop::Collectors::Net::Snapshot.new(
        rx_bytes: 1000_i64, tx_bytes: 500_i64,
        rx_rate: 100.0, tx_rate: 50.0
      )
      s3 = Ctop::Collectors::Net::Snapshot.new(
        rx_bytes: 2000_i64, tx_bytes: 500_i64,
        rx_rate: 100.0, tx_rate: 50.0
      )

      s1.should eq(s2)
      s1.should_not eq(s3)
    end
  end
end
