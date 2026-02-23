# Immutable snapshot of network metrics
record Ctop::Snapshots::Net,
  rx_bytes : Int64,  # Total bytes received
  tx_bytes : Int64,  # Total bytes transmitted
  rx_rate : Float64, # Receive rate in bytes/sec
  tx_rate : Float64  # Transmit rate in bytes/sec
