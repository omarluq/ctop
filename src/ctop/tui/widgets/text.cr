module Ctop::TUI::Widgets::Text
  # Draw a string at position (x, y). Returns x + length for chaining.
  def self.draw(
    tui : Termisu,
    x : Int32,
    y : Int32,
    text : String,
    fg : Termisu::Color = Termisu::Color.white,
    attr : Termisu::Attribute = Termisu::Attribute::None,
  ) : Int32
    text.each_char_with_index do |char, index|
      tui.set_cell(x + index, y, char, fg: fg, attr: attr)
    end
    x + text.size
  end

  # Draw a right-aligned string ending at max_x on row y.
  def self.draw_right(
    tui : Termisu,
    max_x : Int32,
    y : Int32,
    text : String,
    fg : Termisu::Color = Termisu::Color.white,
    attr : Termisu::Attribute = Termisu::Attribute::None,
  ) : Int32
    start_x = max_x - text.size
    draw(tui, start_x, y, text, fg, attr)
  end

  # Fill a row from x to max_x with a character.
  def self.fill_row(
    tui : Termisu,
    y : Int32,
    x_start : Int32,
    x_end : Int32,
    ch : Char = ' ',
    fg : Termisu::Color = Termisu::Color.default,
  )
    x_start.upto(x_end - 1) do |x|
      tui.set_cell(x, y, ch, fg: fg)
    end
  end

  # Draw a horizontal line.
  def self.draw_hline(
    tui : Termisu,
    y : Int32,
    x_start : Int32,
    x_end : Int32,
    ch : Char = '─',
    fg : Termisu::Color = Termisu::Color.white,
  )
    fill_row(tui, y, x_start, x_end, ch, fg)
  end
end
