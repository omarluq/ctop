# Collects network I/O metrics with automatic rate calculation.
#
# ```
# net = Ctop::Collectors::Net.new
# loop do
#   sleep 1
#   snapshot = net.collect
#   puts "Down: #{(snapshot.rx_rate / 1024).round(1)} KB/s"
#   puts "Up: #{(snapshot.tx_rate / 1024).round(1)} KB/s"
# end
# ```
class Ctop::Collectors::Net < Ctop::Collectors::Base
  # Immutable snapshot of network metrics
  record Snapshot,
    rx_bytes : Int64,  # Total bytes received
    tx_bytes : Int64,  # Total bytes transmitted
    rx_rate : Float64, # Receive rate in bytes/sec
    tx_rate : Float64  # Transmit rate in bytes/sec

  @last_rx : Int64 = 0_i64
  @last_tx : Int64 = 0_i64
  @first_collect : Bool = true

  # Collect current network state. First call returns zero rates.
  def collect : Snapshot
    hw = Hardware::Net.new
    rx = hw.in_octets
    tx = hw.out_octets
    elapsed = elapsed_seconds

    # Calculate rates (zero on first call to establish baseline)
    if @first_collect
      @first_collect = false
      rx_rate = 0.0
      tx_rate = 0.0
    else
      rx_rate = (rx - @last_rx) / elapsed
      tx_rate = (tx - @last_tx) / elapsed
    end

    @last_rx = rx
    @last_tx = tx

    Snapshot.new(
      rx_bytes: rx,
      tx_bytes: tx,
      rx_rate: rx_rate.clamp(0.0, Float64::MAX),
      tx_rate: tx_rate.clamp(0.0, Float64::MAX)
    )
  end

  # Reset state for fresh rate calculations
  def reset
    reset_timing
    @last_rx = 0_i64
    @last_tx = 0_i64
    @first_collect = true
  end
end
