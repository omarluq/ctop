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

  BAR_WIDTH = 12

  # Draw the top summary panels (CPU, MEM, NET).
  def self.draw_summary(
    tui : Termisu,
    y : Int32,
    metrics : Snapshots::Metrics,
    color : Bool,
  )
    x = MARGIN + 1
    x = draw_gauge(tui, x, y, "CPU", metrics.cpu.usage, color)
    x = Widgets::Text.draw(tui, x, y, "│ ", fg: Termisu::Color.bright_black)
    x = draw_gauge(tui, x, y, "MEM", metrics.memory.percent, color)
    draw_mem_total(tui, x, y, metrics.memory)
    draw_net_stats(tui, y + 1, metrics.net, color)
  end

  # Draw the process table header with separator.
  def self.draw_proc_header(
    tui : Termisu,
    y : Int32,
    color : Bool,
  )
    width, _ = tui.size
    Widgets::Box.draw_hline(tui, MARGIN, y, width - 2 * MARGIN, '─', Termisu::Color.bright_black)

    y += 1
    fg = color ? Termisu::Color.bright_yellow : Termisu::Color.white
    Widgets::Text.draw(tui, COL_PID_X, y, "PID       ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_NAME_X, y, "NAME                ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_CPU_X, y, "CPU%     ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_MEM_X, y, "MEM         ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_STATE_X, y, "STATE   ", fg: fg, attr: Termisu::Attribute::Bold)
    Widgets::Text.draw(tui, COL_CMD_X, y, "CMD", fg: fg, attr: Termisu::Attribute::Bold)

    Widgets::Box.draw_hline(tui, MARGIN, y + 1, width - 2 * MARGIN, '═', Termisu::Color.bright_black)
  end

  # Draw a single process row.
  def self.draw_proc_row(
    tui : Termisu,
    y : Int32,
    proc : Snapshots::ProcessInfo,
    color : Bool,
    selected : Bool = false,
    width : Int32 = 80,
  )
    row_fg, row_attr = Style.row_style(selected)

    Widgets::Text.draw(tui, COL_PID_X, y, sprintf("%-9d", proc.pid),
      fg: selected ? Termisu::Color.cyan : Termisu::Color.bright_black, attr: row_attr)

    name_max = COL_CPU_X - COL_NAME_X - 1
    Widgets::Text.draw(tui, COL_NAME_X, y,
      Formatter.truncate(proc.name, name_max).ljust(name_max), fg: row_fg, attr: row_attr)

    Widgets::Text.draw(tui, COL_CPU_X, y, sprintf("%-8.1f%%", proc.cpu_percent),
      fg: Style.select_or_color(selected, color, Style.threshold_color(proc.cpu_percent)), attr: row_attr)

    mem_pct = (proc.memory_kb.to_f / (1024 * 1024) * 100).clamp(0.0, 100.0)
    Widgets::Text.draw(tui, COL_MEM_X, y, Formatter.format_memory(proc.memory_kb).ljust(12),
      fg: Style.select_or_color(selected, color, Style.threshold_color(mem_pct)), attr: row_attr)

    Widgets::Text.draw(tui, COL_STATE_X, y, sprintf("%-7s", Style.state_char(proc.state)),
      fg: Style.select_or_color(selected, color, Style.state_color(proc.state)), attr: row_attr)

    cmd = proc.command.empty? ? proc.name : File.basename(proc.command.split('\0').first)
    Widgets::Text.draw(tui, COL_CMD_X, y,
      Formatter.truncate(cmd, width - COL_CMD_X - MARGIN - 1), fg: row_fg, attr: row_attr)
  end

  # Draw a labeled gauge (bar + percent).
  private def self.draw_gauge(
    tui : Termisu,
    x : Int32,
    y : Int32,
    label : String,
    percent : Float64,
    color : Bool,
  ) : Int32
    x = Widgets::Text.draw(tui, x, y, "#{label} ", fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)
    Widgets::Bar.draw_threshold(tui, x, y, BAR_WIDTH, percent, color_enabled: color)
    x += BAR_WIDTH
    pct_fg = color ? Style.threshold_color(percent) : Termisu::Color.white
    Widgets::Text.draw(tui, x, y, sprintf(" %5.1f%% ", percent), fg: pct_fg, attr: Termisu::Attribute::Bold)
  end

  # Draw memory total (used/total GiB).
  private def self.draw_mem_total(tui : Termisu, x : Int32, y : Int32, mem : Snapshots::Memory)
    used_gib = mem.used_bytes.to_f / (1024 ** 3)
    total_gib = mem.total_bytes.to_f / (1024 ** 3)
    Widgets::Text.draw(tui, x, y, sprintf(" %.1f/%.1f GiB", used_gib, total_gib), fg: Termisu::Color.white)
  end

  # Draw network rx/tx rates.
  private def self.draw_net_stats(tui : Termisu, y : Int32, net : Snapshots::Net, color : Bool)
    x = MARGIN + 1
    x = Widgets::Text.draw(tui, x, y, "NET ", fg: Termisu::Color.cyan, attr: Termisu::Attribute::Bold)
    x = Widgets::Text.draw(tui, x, y, "↓#{Formatter.format_bytes(net.rx_rate)}/s ",
      fg: color ? Termisu::Color.green : Termisu::Color.white)
    Widgets::Text.draw(tui, x, y, "↑#{Formatter.format_bytes(net.tx_rate)}/s",
      fg: color ? Termisu::Color.blue : Termisu::Color.white)
  end
end
