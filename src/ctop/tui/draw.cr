require "../tui/widgets/bar"
require "../tui/widgets/text"

# Drawing functions for ctop panels.
module Ctop::TUI::Draw
  Log = ::Log.for("ctop.draw")

  # Margins
  TOP_MARGIN  = 2
  LEFT_MARGIN = 2

  # Panel height constants (including spacing)
  CPU_HEIGHT    = 2 # 1 line content + 1 blank
  MEMORY_HEIGHT = 4 # 1 separator + 2 lines content + 1 blank
  NET_HEIGHT    = 2 # 1 line content + 1 blank
  HEADER_HEIGHT = 3 # 1 separator + 1 header + 1 hline

  # Total height of non-process panels
  PANELS_HEIGHT = CPU_HEIGHT + MEMORY_HEIGHT + NET_HEIGHT + HEADER_HEIGHT

  # Process table column positions (with generous spacing, offset by left margin)
  COL_PID_X  = LEFT_MARGIN
  COL_NAME_X = LEFT_MARGIN + 10
  COL_CPU_X  = LEFT_MARGIN + 38
  COL_MEM_X  = LEFT_MARGIN + 48

  # Draw the CPU panel.
  # Format: CPU [████████░░░░░░] 58.3%
  #         (blank line)
  def self.draw_cpu(
    tui : Termisu,
    y : Int32,
    snapshot : Ctop::Snapshots::CPU,
    color : Bool = true,
  )
    x = LEFT_MARGIN

    label = "CPU "
    x = Ctop::TUI::Widgets::Text.draw(tui, x, y, label, fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)

    bar_width = 20
    Ctop::TUI::Widgets::Bar.draw_threshold(tui, x, y, bar_width, snapshot.usage, color_enabled: color)

    x += bar_width
    pct = sprintf(" %5.1f%%", snapshot.usage)
    fg = color ? threshold_color(snapshot.usage) : Termisu::Color.white
    Ctop::TUI::Widgets::Text.draw(tui, x, y, pct, fg: fg, attr: Termisu::Attribute::Bold)
  end

  # Draw the Memory panel.
  # Format: ───────────────────────────────────────────
  #         MEM [██████░░░░░░░░] 42.1%
  #              3.2 GiB / 8.0 GiB
  #         (blank line)
  def self.draw_memory(
    tui : Termisu,
    y : Int32,
    snapshot : Ctop::Snapshots::Memory,
    color : Bool = true,
  )
    # Separator line above
    width, _ = tui.size
    Ctop::TUI::Widgets::Text.draw_hline(tui, y, LEFT_MARGIN, width - LEFT_MARGIN, '─', fg: Termisu::Color.bright_black)

    # Line 1: Label + bar + percentage
    x = LEFT_MARGIN
    label = "MEM "
    x = Ctop::TUI::Widgets::Text.draw(tui, x, y + 1, label, fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)

    bar_width = 20
    Ctop::TUI::Widgets::Bar.draw_threshold(tui, x, y + 1, bar_width, snapshot.percent, color_enabled: color)

    x += bar_width
    pct = sprintf(" %5.1f%%", snapshot.percent)
    fg = color ? threshold_color(snapshot.percent) : Termisu::Color.white
    Ctop::TUI::Widgets::Text.draw(tui, x, y + 1, pct, fg: fg, attr: Termisu::Attribute::Bold)

    # Line 2: used / total (using binary units)
    used_gib = snapshot.used_bytes.to_f / (1024 ** 3)
    total_gib = snapshot.total_bytes.to_f / (1024 ** 3)
    info = sprintf("     %.1f GiB / %.1f GiB", used_gib, total_gib)
    Ctop::TUI::Widgets::Text.draw(tui, LEFT_MARGIN, y + 2, info, fg: Termisu::Color.white)
  end

  # Draw the Network panel.
  # Format: NET ↓ 1.2 MiB/s   ↑ 256 KiB/s
  #         (blank line)
  def self.draw_net(
    tui : Termisu,
    y : Int32,
    snapshot : Ctop::Snapshots::Net,
    color : Bool = true,
  )
    x = LEFT_MARGIN
    label = "NET "
    x = Ctop::TUI::Widgets::Text.draw(tui, x, y, label, fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)

    # Receive (download)
    rx_str = format_bytes(snapshot.rx_rate)
    rx = "↓ #{rx_str}/s"
    fg = color ? Termisu::Color.green : Termisu::Color.white
    x = Ctop::TUI::Widgets::Text.draw(tui, x, y, rx, fg: fg)

    # Extra spacing between RX and TX
    x += 3

    # Transmit (upload)
    tx_str = format_bytes(snapshot.tx_rate)
    tx = "↑ #{tx_str}/s"
    fg = color ? Termisu::Color.blue : Termisu::Color.white
    Ctop::TUI::Widgets::Text.draw(tui, x, y, tx, fg: fg)
  end

  # Draw the process table header.
  # Format: ───────────────────────────────────────────
  #         PID      NAME                   CPU%     MEM
  #         ══════════════════════════════════════════
  def self.draw_proc_header(
    tui : Termisu,
    y : Int32,
    color : Bool = true,
  )
    width, _ = tui.size

    # Separator line above
    Ctop::TUI::Widgets::Text.draw_hline(tui, y, LEFT_MARGIN, width - LEFT_MARGIN, '─', fg: Termisu::Color.bright_black)

    fg = color ? Termisu::Color.bright_yellow : Termisu::Color.white
    Ctop::TUI::Widgets::Text.draw(tui, COL_PID_X, y + 1, "PID", fg: fg, attr: Termisu::Attribute::Bold)
    Ctop::TUI::Widgets::Text.draw(tui, COL_NAME_X, y + 1, "NAME", fg: fg, attr: Termisu::Attribute::Bold)
    Ctop::TUI::Widgets::Text.draw(tui, COL_CPU_X, y + 1, "CPU%", fg: fg, attr: Termisu::Attribute::Bold)
    Ctop::TUI::Widgets::Text.draw(tui, COL_MEM_X, y + 1, "MEM", fg: fg, attr: Termisu::Attribute::Bold)

    # Double line under header
    Ctop::TUI::Widgets::Text.draw_hline(tui, y + 2, LEFT_MARGIN, width - LEFT_MARGIN, '═', fg: Termisu::Color.bright_black)
  end

  # Draw a single process row.
  # Format: 1234    chrome                 1.8%   439M
  def self.draw_proc_row(
    tui : Termisu,
    y : Int32,
    proc : Ctop::Snapshots::ProcessInfo,
    color : Bool = true,
  )
    # PID
    Ctop::TUI::Widgets::Text.draw(tui, COL_PID_X, y, sprintf("%-7d", proc.pid), fg: Termisu::Color.bright_black)

    # NAME (truncated to fit)
    name = proc.name[0..26]
    name = name.ljust(27)
    Ctop::TUI::Widgets::Text.draw(tui, COL_NAME_X, y, name, fg: Termisu::Color.white)

    # CPU% (right-aligned under header)
    cpu = sprintf("%6.1f%%", proc.cpu_percent)
    cpu_fg = color ? threshold_color(proc.cpu_percent) : Termisu::Color.white
    Ctop::TUI::Widgets::Text.draw(tui, COL_CPU_X, y, cpu, fg: cpu_fg)

    # MEM (using proper binary units with decimal precision)
    mem = format_memory_clean(proc.memory_kb)
    Ctop::TUI::Widgets::Text.draw(tui, COL_MEM_X, y, mem, fg: Termisu::Color.white)
  end

  # Format bytes/sec as human readable (KiB/s, MiB/s, GiB/s)
  private def self.format_bytes(rate : Float64) : String
    return "   0 B" if rate < 1024

    kib = rate / 1024
    return sprintf("%4.0f KiB", kib) if kib < 1024

    mib = kib / 1024
    return sprintf("%4.1f MiB", mib) if mib < 1024

    gib = mib / 1024
    sprintf("%4.2f GiB", gib)
  end

  # Format KiB as human readable with proper decimal handling
  # Shows: "123K", "45.6M", "1.2G"
  private def self.format_memory_clean(kib : Int32) : String
    return "#{kib}K" if kib < 1024

    # Use float division for proper decimal
    mib = kib.to_f / 1024
    return sprintf("%.1fM", mib) if mib < 1024

    gib = mib / 1024
    sprintf("%.1fG", gib)
  end

  # Get color based on threshold (green < 50 < yellow < 80 < red)
  private def self.threshold_color(percent : Float64) : Termisu::Color
    pct = percent.nan? || percent.infinite? ? 0.0 : percent
    case
    when pct < 50 then Termisu::Color.green
    when pct < 80 then Termisu::Color.yellow
    else               Termisu::Color.red
    end
  end
end
