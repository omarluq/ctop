module Ctop::TUI::Widgets::Text
  # Draw a string at position (x, y). Returns x + length for chaining.
  def self.draw(
    tui : Termisu,
    x : Int32,
    y : Int32,
    text : String,
    fg : Termisu::Color = Termisu::Color.white,
    attr : Termisu::Attribute = Termisu::Attribute::None,
    bg : Termisu::Color = Termisu::Color.default,
  ) : Int32
    text.each_char_with_index do |char, index|
      tui.set_cell(x + index, y, char, fg: fg, attr: attr, bg: bg)
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
end
