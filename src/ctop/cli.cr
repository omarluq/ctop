require "option_parser"

# CLI entry point using Crystal's built-in OptionParser.
#
# Usage:
#   ctop                           # start with defaults
#   ctop -i 0.5 -n 50             # 500ms interval, 50 processes
#   ctop --interval 2 --no-color   # 2s interval, monochrome
#   ctop --version                 # show version
#   ctop --help                    # show help
module Ctop::CLI
  def self.run
    interval = 1.0
    proc_limit = 100
    color = true

    OptionParser.parse do |parser|
      parser.banner = "Usage: ctop [flags]"

      parser.on("-i SECONDS", "--interval=SECONDS", "Refresh interval in seconds") do |val|
        interval = val.to_f64
      end

      parser.on("-n COUNT", "--proc-limit=COUNT", "Max processes to display") do |val|
        proc_limit = val.to_i32
      end

      parser.on("--no-color", "Disable colored output") do
        color = false
      end

      parser.on("-V", "--version", "Show version") do
        puts Ctop::VERSION
        exit
      end

      parser.on("-h", "--help", "Show help") do
        puts parser
        exit
      end
    end

    Ctop.new(interval: interval, proc_limit: proc_limit, color: color).run
  end
end
