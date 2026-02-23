require "../tui/widgets/bar"
require "../tui/widgets/text"
require "../tui/widgets/box"

# Btop-style drawing layout.
# ┌────────────────────────────────────────────────────────────────────┐
# │ CPU ████████████░░░░ 45%   MEM ██████████░░░░░ 62%   3.2/8.0 GiB   │
# │ NET ↓12.5MiB/s ↑2.3MiB/s                                           │
# ├────────────────────────────────────────────────────────────────────┤
# │ PID    NAME             CPU%    MEM        STATE    CMD            │
# │ ═════════════════════════════════════════════════════════════════  │
# │ 1234   chromium         12.3%   1.2 GiB    Running  /usr/bin/chr.. │
# └────────────────────────────────────────────────────────────────────┘
module Ctop::TUI::Draw
  Log = ::Log.for("ctop.draw")

  # Layout constants
  MARGIN        = 1
  HEADER_HEIGHT = 3
  PANELS_HEIGHT = 2

  # Process table columns
  COL_PID_X   = MARGIN + 1
  COL_NAME_X  = COL_PID_X + 10
  COL_CPU_X   = COL_NAME_X + 20
  COL_MEM_X   = COL_CPU_X + 9
  COL_STATE_X = COL_MEM_X + 11
  COL_CMD_X   = COL_STATE_X + 8

  # Draw the top summary panels (CPU, MEM, NET).
  def self.draw_summary(
    tui : Termisu,
    y : Int32,
    metrics : Snapshots::Metrics,
    color : Bool,
  )
    # Line 1: CPU bar + percent, MEM bar + percent, memory total
    x = MARGIN + 1

    # CPU section
    x = Widgets::Text.draw(tui, x, y, "CPU ", fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)
    bar_width = 12
    Widgets::Bar.draw_threshold(tui, x, y, bar_width, metrics.cpu.usage, color_enabled: color)
    x += bar_width
    pct = sprintf(" %5.1f%% ", metrics.cpu.usage)
    pct_fg = color ? threshold_color(metrics.cpu.usage) : Termisu::Color.white
    x = Widgets::Text.draw(tui, x, y, pct, fg: pct_fg, attr: Termisu::Attribute::Bold)

    # Separator
    x = Widgets::Text.draw(tui, x, y, "│ ", fg: Termisu::Color.bright_black)

    # MEM section
    x = Widgets::Text.draw(tui, x, y, "MEM ", fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)
    Widgets::Bar.draw_threshold(tui, x, y, bar_width, metrics.memory.percent, color_enabled: color)
    x += bar_width
    pct = sprintf(" %5.1f%% ", metrics.memory.percent)
    pct_fg = color ? threshold_color(metrics.memory.percent) : Termisu::Color.white
    x = Widgets::Text.draw(tui, x, y, pct, fg: pct_fg, attr: Termisu::Attribute::Bold)

    # Memory usage
    used_gib = metrics.memory.used_bytes.to_f / (1024 ** 3)
    total_gib = metrics.memory.total_bytes.to_f / (1024 ** 3)
    Widgets::Text.draw(tui, x, y, sprintf(" %.1f/%.1f GiB", used_gib, total_gib), fg: Termisu::Color.white)

    # Line 2: Network stats
    x = MARGIN + 1
    rx_str = format_bytes(metrics.net.rx_rate)
    tx_str = format_bytes(metrics.net.tx_rate)
    x = Widgets::Text.draw(tui, x, y + 1, "NET ", fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)
    rx_fg = color ? Termisu::Color.green : Termisu::Color.white
    x = Widgets::Text.draw(tui, x, y + 1, "↓#{rx_str}/s ", fg: rx_fg)
    tx_fg = color ? Termisu::Color.blue : Termisu::Color.white
    Widgets::Text.draw(tui, x, y + 1, "↑#{tx_str}/s", fg: tx_fg)
  end

  # Draw the process table header with separator.
  def self.draw_proc_header(
    tui : Termisu,
    y : Int32,
    color : Bool,
  )
    width, _ = tui.size

    # Separator line
    Widgets::Box.draw_hline(tui, MARGIN, y, width - 2 * MARGIN, '─', Termisu::Color.bright_black)

    # Header row
    y += 1
    fg = color ? Termisu::Color.bright_yellow : Termisu::Color.white
    Widgets::Text.draw(tui, COL_PID_X, y, "PID       ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_NAME_X, y, "NAME                ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_CPU_X, y, "CPU%     ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_MEM_X, y, "MEM         ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_STATE_X, y, "STATE   ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_CMD_X, y, "CMD", fg: fg, attr: Termisu::Attribute::Bold)

    # Double line under header
    Widgets::Box.draw_hline(tui, MARGIN, y + 1, width - 2 * MARGIN, '═', Termisu::Color.bright_black)
  end

  # Draw a single process row with optional selection highlight.
  def self.draw_proc_row(
    tui : Termisu,
    y : Int32,
    proc : Snapshots::ProcessInfo,
    color : Bool,
    selected : Bool = false,
    width : Int32 = 80,
  )
    row_fg, row_attr = row_style(selected)

    Widgets::Text.draw(tui, COL_PID_X, y, sprintf("%-9d", proc.pid),
      fg: selected ? Termisu::Color.cyan : Termisu::Color.bright_black, attr: row_attr)

    name_max_width = COL_CPU_X - COL_NAME_X - 1
    name = truncate_string(proc.name, name_max_width).ljust(name_max_width)
    Widgets::Text.draw(tui, COL_NAME_X, y, name, fg: row_fg, attr: row_attr)

    cpu_fg = select_or_color(selected, color, threshold_color(proc.cpu_percent))
    Widgets::Text.draw(tui, COL_CPU_X, y, sprintf("%-8.1f%%", proc.cpu_percent), fg: cpu_fg, attr: row_attr)

    mem = format_memory(proc.memory_kb).ljust(12)
    mem_pct = (proc.memory_kb.to_f / (1024 * 1024) * 100).clamp(0.0, 100.0)
    Widgets::Text.draw(tui, COL_MEM_X, y, mem, fg: select_or_color(selected, color, threshold_color(mem_pct)), attr: row_attr)

    Widgets::Text.draw(tui, COL_STATE_X, y, sprintf("%-7s", state_char(proc.state)),
      fg: select_or_color(selected, color, state_color(proc.state)), attr: row_attr)

    cmd = proc.command.empty? ? proc.name : File.basename(proc.command.split('\0').first)
    Widgets::Text.draw(tui, COL_CMD_X, y, truncate_string(cmd, width - COL_CMD_X - MARGIN - 1), fg: row_fg, attr: row_attr)
  end

  # Row style based on selection state.
  private def self.row_style(selected : Bool) : {Termisu::Color, Termisu::Attribute}
    selected ? {Termisu::Color.cyan, Termisu::Attribute::Bold} : {Termisu::Color.white, Termisu::Attribute::None}
  end

  # Return cyan if selected, colored value if color enabled, else white.
  private def self.select_or_color(selected : Bool, color : Bool, colored : Termisu::Color) : Termisu::Color
    return Termisu::Color.cyan if selected
    color ? colored : Termisu::Color.white
  end

  # Get color for process state.
  private def self.state_color(state : Hardware::PID::Stat::State) : Termisu::Color
    case state
    when .running?  then Termisu::Color.green
    when .sleeping? then Termisu::Color.blue
    when .stopped?  then Termisu::Color.red
    when .zombie?   then Termisu::Color.bright_magenta
    else                 Termisu::Color.white
    end
  end

  # Format memory as human readable.
  private def self.format_memory(kib : Int32) : String
    return "#{kib}K  " if kib < 1024

    mib = kib.to_f / 1024
    return sprintf("%.1fM  ", mib) if mib < 1024

    gib = mib / 1024
    sprintf("%.1fG  ", gib)
  end

  # Format bytes per second as human readable.
  private def self.format_bytes(rate : Float64) : String
    return "    0 B" if rate < 1024

    kib = rate / 1024
    return sprintf("%6.0f KiB", kib) if kib < 1024

    mib = kib / 1024
    return sprintf("%6.1f MiB", mib) if mib < 1024

    gib = mib / 1024
    sprintf("%6.2f GiB", gib)
  end

  # Get color based on threshold.
  private def self.threshold_color(percent : Float64) : Termisu::Color
    pct = percent.nan? || percent.infinite? ? 0.0 : percent
    case
    when pct < 50 then Termisu::Color.green
    when pct < 80 then Termisu::Color.yellow
    else               Termisu::Color.red
    end
  end

  # Truncate string to max width, adding ".." if truncated.
  private def self.truncate_string(str : String, max_width : Int32) : String
    return str if str.size <= max_width
    return "…" if max_width <= 1
    str[0..(max_width - 2)] + "…"
  end

  # Convert process state to single character.
  private def self.state_char(state : Hardware::PID::Stat::State) : String
    case state
    when .running?  then "R"
    when .sleeping? then "S"
    when .stopped?  then "T"
    when .zombie?   then "Z"
    else                 "?"
    end
  end
end
