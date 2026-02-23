module Ctop::TUI::Widgets::Bar
  # Draw a horizontal progress bar.
  #
  # - x, y: starting position
  # - width: total width including brackets
  # - percent: 0.0 to 100.0
  def self.draw(
    tui : Termisu,
    x : Int32,
    y : Int32,
    width : Int32,
    percent : Float64,
    fg : Termisu::Color = Termisu::Color.green,
    filled : Char = '█',
    empty : Char = '░',
  )
    return if width < 3

    inner = width - 2
    pct = percent.nan? || percent.infinite? ? 0.0 : percent
    filled_count = (pct / 100.0 * inner).clamp(0.0, inner.to_f).to_i32

    tui.set_cell(x, y, '[', fg: fg)
    inner.times do |i|
      ch = i < filled_count ? filled : empty
      tui.set_cell(x + 1 + i, y, ch, fg: fg)
    end
    tui.set_cell(x + width - 1, y, ']', fg: fg)
  end

  # Draw a bar with color based on thresholds: green < 50% < yellow < 80% < red
  # When color_enabled is false, uses white for monochrome output.
  def self.draw_threshold(
    tui : Termisu,
    x : Int32,
    y : Int32,
    width : Int32,
    percent : Float64,
    color_enabled : Bool = true,
    filled : Char = '█',
    empty : Char = '░',
  )
    pct = percent.nan? || percent.infinite? ? 0.0 : percent
    fg = if color_enabled
           case
           when pct < 50 then Termisu::Color.green
           when pct < 80 then Termisu::Color.yellow
           else               Termisu::Color.red
           end
         else
           Termisu::Color.white
         end
    draw(tui, x, y, width, pct, fg, filled, empty)
  end
end
