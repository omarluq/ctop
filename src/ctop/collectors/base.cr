require "hardware"

# Base class for all collectors providing shared timing utilities.
#
# Collectors follow a consistent pattern:
# - Each defines a `Snapshot` record type for immutable data
# - Each implements `collect` returning its Snapshot type
# - Rate calculations use `elapsed_seconds` from base
abstract class Ctop::Collectors::Base
  @last_time : Time::Span?

  # Returns seconds since last collection, defaulting to 1.0 for first call.
  # Used for rate calculations (bytes/sec, etc.)
  protected def elapsed_seconds : Float64
    now = Time.monotonic
    result = @last_time.try { |last| (now - last).total_seconds } || 1.0
    @last_time = now
    result.clamp(0.001, Float64::MAX) # Prevent division by zero
  end

  # Reset timing state (useful for tests)
  def reset_timing
    @last_time = nil
  end
end
