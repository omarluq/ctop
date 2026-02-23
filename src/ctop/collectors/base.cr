require "hardware"

# Base class for all collectors providing shared timing utilities.
#
# Generic type `T` represents the Snapshot type returned by `collect`.
# Each collector defines its own Snapshot record and inherits from Base(Snapshot).
#
# ```
# class CPU < Base(CPU::Snapshot)
#   record Snapshot, usage : Float64
#
#   def collect : Snapshot
#     Snapshot.new(usage: 50.0)
#   end
# end
# ```
abstract class Ctop::Collectors::Base(T)
  # Collect metrics and return an immutable snapshot
  abstract def collect : T

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
