# Box drawing utilities for creating bordered panels.
module Ctop::TUI::Widgets::Box
  # Box drawing characters
  private BOX_CHARS = {
    h: '─', v: '│',
    tl: '┌', tr: '┐',
    bl: '└', br: '┘',
  }

  # Draw a framed box with optional title.
  def self.draw_frame(
    tui : Termisu,
    x : Int32,
    y : Int32,
    width : Int32,
    height : Int32,
    title : String? = nil,
    fg : Termisu::Color = Termisu::Color.cyan,
  )
    return if width < 2 || height < 2

    # Corners
    tui.set_cell(x, y, BOX_CHARS[:tl], fg: fg)
    tui.set_cell(x + width - 1, y, BOX_CHARS[:tr], fg: fg)
    tui.set_cell(x, y + height - 1, BOX_CHARS[:bl], fg: fg)
    tui.set_cell(x + width - 1, y + height - 1, BOX_CHARS[:br], fg: fg)

    # Top border with title
    draw_hline(tui, x + 1, y, width - 2, BOX_CHARS[:h], fg)
    if title && !title.empty? && title.size < width - 4
      title_x = x + 2
      title.chars.each_with_index do |char, index|
        break if title_x + index >= x + width - 2
        tui.set_cell(title_x + index, y, char, fg: fg)
      end
    end

    # Bottom border
    draw_hline(tui, x + 1, y + height - 1, width - 2, BOX_CHARS[:h], fg)

    # Vertical borders
    (y + 1).upto(y + height - 2) do |row_y|
      tui.set_cell(x, row_y, BOX_CHARS[:v], fg: fg)
      tui.set_cell(x + width - 1, row_y, BOX_CHARS[:v], fg: fg)
    end
  end

  # Draw a horizontal line.
  def self.draw_hline(
    tui : Termisu,
    x : Int32,
    y : Int32,
    width : Int32,
    ch : Char,
    fg : Termisu::Color,
  )
    width.times do |index|
      tui.set_cell(x + index, y, ch, fg: fg)
    end
  end

  # Draw a highlighted row background (full width).
  def self.draw_highlight(
    tui : Termisu,
    x : Int32,
    y : Int32,
    width : Int32,
    bg : Termisu::Color = Termisu::Color.bright_blue,
  )
    width.times do |col_x|
      tui.set_cell(x + col_x, y, ' ', fg: Termisu::Color.white, bg: bg)
    end
  end

  # Fill area with spaces (for clearing).
  def self.clear_rect(
    tui : Termisu,
    x : Int32,
    y : Int32,
    width : Int32,
    height : Int32,
  )
    height.times do |row_y|
      width.times do |col_x|
        tui.set_cell(x + col_x, y + row_y, ' ')
      end
    end
  end
end
