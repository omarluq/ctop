require "log"
require "termisu"

# Terminal-based system monitor.
#
# Collects CPU, memory, network, and process metrics and renders
# them in a TUI using Termisu's event loop and kernel-backed timer.
class Ctop
  Log = ::Log.for("ctop")

  getter interval : Float64
  getter proc_limit : Int32
  getter? color : Bool

  def initialize(
    @interval : Float64 = 1.0,
    @proc_limit : Int32 = 100,
    @color : Bool = true,
  )
  end

  # Start the TUI event loop.
  #
  # Uses Termisu's kernel-backed timer to emit Tick events at the
  # configured interval. Each tick collects system metrics and
  # redraws the display.
  def run
    tui = Termisu.new
    tui.enable_timer(interval.seconds)
    tui.hide_cursor

    collectors = Collectors::Manager.new

    # Initial draw
    metrics = collectors.collect(proc_limit)
    draw(tui, metrics)
    tui.render

    tui.each_event do |event|
      case event
      when Termisu::Event::Tick
        metrics = collectors.collect(proc_limit)
        tui.clear
        draw(tui, metrics)
        tui.render
      when Termisu::Event::Resize
        tui.sync
      when Termisu::Event::Key
        break if event.key.q? || event.key.escape? || event.ctrl_c?
      end
    end
  ensure
    tui.try &.close
  end

  # Draw all panels top-to-bottom.
  private def draw(tui : Termisu, metrics : Snapshots::Metrics)
    y = Ctop::TUI::Draw::TOP_MARGIN

    # CPU panel
    TUI::Draw.draw_cpu(tui, y, metrics.cpu, color?)
    y += Ctop::TUI::Draw::CPU_HEIGHT

    # Memory panel
    TUI::Draw.draw_memory(tui, y, metrics.memory, color?)
    y += TUI::Draw::MEMORY_HEIGHT

    # Network panel
    TUI::Draw.draw_net(tui, y, metrics.net, color?)
    y += TUI::Draw::NET_HEIGHT

    # Process table header (includes separator and hline)
    TUI::Draw.draw_proc_header(tui, y, color?)
    y += TUI::Draw::HEADER_HEIGHT

    # Process rows (fill remaining height)
    _, height = tui.size
    available = height - y
    count = {available, metrics.proc.processes.size}.min

    count.times do |i|
      TUI::Draw.draw_proc_row(tui, y + i, metrics.proc.processes[i], color?)
    end
  end
end

require "./ctop/snapshots/**"
require "./ctop/**"

# Only run CLI when this file is executed directly (not during specs)
Ctop::CLI.run unless PROGRAM_NAME.includes?("spec")
