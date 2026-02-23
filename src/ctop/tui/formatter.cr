# String and number formatting utilities for TUI display.
module Ctop::TUI::Formatter
  # Format memory as human readable.
  def self.format_memory(kib : Int32) : String
    return "#{kib}K  " if kib < 1024

    mib = kib.to_f / 1024
    return sprintf("%.1fM  ", mib) if mib < 1024

    gib = mib / 1024
    sprintf("%.1fG  ", gib)
  end

  # Format bytes per second as human readable.
  def self.format_bytes(rate : Float64) : String
    return "    0 B" if rate < 1024

    kib = rate / 1024
    return sprintf("%6.0f KiB", kib) if kib < 1024

    mib = kib / 1024
    return sprintf("%6.1f MiB", mib) if mib < 1024

    gib = mib / 1024
    sprintf("%6.2f GiB", gib)
  end

  # Truncate string to max width, adding "…" if truncated.
  def self.truncate(str : String, max_width : Int32) : String
    return str if str.size <= max_width
    return "…" if max_width <= 1
    str[0..(max_width - 2)] + "…"
  end
end
