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
  property selected : Int32 = 0

  def initialize(
    @interval : Float64 = 1.0,
    @proc_limit : Int32 = 100,
    @color : Bool = true,
  )
  end

  # Start the TUI event loop.
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
        case event.key
        when .q?, .escape?
          break
        when .up?
          @selected = (@selected - 1).clamp(0, metrics.proc.processes.size - 1)
          tui.clear
          draw(tui, metrics)
          tui.render
        when .down?
          @selected = (@selected + 1).clamp(0, metrics.proc.processes.size - 1)
          tui.clear
          draw(tui, metrics)
          tui.render
        end
        break if event.ctrl_c?
      end
    end
  ensure
    tui.try &.close
  end

  # Draw all panels using btop-style layout.
  private def draw(tui : Termisu, metrics : Snapshots::Metrics)
    width, height = tui.size
    y = TUI::Draw::MARGIN

    # Summary panels (CPU, MEM, NET on 2 lines)
    TUI::Draw.draw_summary(tui, y, metrics, color?)
    y += TUI::Draw::PANELS_HEIGHT

    # Process table header
    TUI::Draw.draw_proc_header(tui, y, color?)
    y += TUI::Draw::HEADER_HEIGHT

    # Process rows
    available = height - y - TUI::Draw::MARGIN
    count = {available, metrics.proc.processes.size}.min

    # Clamp selection
    @selected = @selected.clamp(0, {count - 1, 0}.max)

    count.times do |i|
      TUI::Draw.draw_proc_row(tui, y + i, metrics.proc.processes[i], color?,
        selected: i == @selected, width: width)
    end
  end
end

require "./ctop/snapshots/**"
require "./ctop/**"

# Only run CLI when this file is executed directly (not during specs)
Ctop::CLI.run unless PROGRAM_NAME.includes?("spec")
