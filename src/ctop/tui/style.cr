# Color and style helpers for TUI drawing.
module Ctop::TUI::Style
  # Row foreground color and attribute based on selection state.
  def self.row_style(selected : Bool) : {Termisu::Color, Termisu::Attribute}
    selected ? {Termisu::Color.cyan, Termisu::Attribute::Bold} : {Termisu::Color.white, Termisu::Attribute::None}
  end

  # Return cyan if selected, colored value if color enabled, else white.
  def self.select_or_color(selected : Bool, color : Bool, colored : Termisu::Color) : Termisu::Color
    return Termisu::Color.cyan if selected
    color ? colored : Termisu::Color.white
  end

  # Get color for percent-based thresholds (green < 50, yellow < 80, red).
  def self.threshold_color(percent : Float64) : Termisu::Color
    pct = percent.nan? || percent.infinite? ? 0.0 : percent
    case
    when pct < 50 then Termisu::Color.green
    when pct < 80 then Termisu::Color.yellow
    else               Termisu::Color.red
    end
  end

  # Get color for process state.
  def self.state_color(state : Hardware::PID::Stat::State) : Termisu::Color
    case state
    when .running?  then Termisu::Color.green
    when .sleeping? then Termisu::Color.blue
    when .stopped?  then Termisu::Color.red
    when .zombie?   then Termisu::Color.bright_magenta
    else                 Termisu::Color.white
    end
  end

  # Convert process state to single character.
  def self.state_char(state : Hardware::PID::Stat::State) : String
    case state
    when .running?  then "R"
    when .sleeping? then "S"
    when .stopped?  then "T"
    when .zombie?   then "Z"
    else                 "?"
    end
  end
end
