require "option_parser"
require "file_utils"
require "crypto/subtle"
require "io"

require "./colors"
require "./config"
require "./file_watcher"
require "./app"
require "./utils"

def main
  config = Foxtail::Config.new

  OptionParser.parse do |parser|
    parser.banner = "Usage: foxtail [options] <file...>"
    parser.separator ""
    parser.separator "Options:"

    parser.on("-n", "--lines=NUMBER", "Output last N lines") do |lines_str|
      lines = lines_str.to_i?
      unless lines && lines > 0
        STDERR.puts "Error: Invalid number of lines: #{lines_str}"
        exit 1
      end
      config.lines = lines
    end

    parser.on("--grep=REGEX", "Filter lines by regex pattern") do |pattern|
      if pattern.empty?
        config.grep_pattern = Regex.new(".*", config.ignore_case ? Regex::Options::IGNORE_CASE : Regex::Options::None)
      else
        config.ignore_case = true unless pattern.includes?("(?i)")
        config.grep_pattern = Regex.new(pattern, config.ignore_case ? Regex::Options::IGNORE_CASE : Regex::Options::None)
      end
    end

    parser.on("--ignore-case", "Case-insensitive grep") do
      config.ignore_case = true
      if existing = config.grep_pattern
        config.grep_pattern = Regex.new(existing.source, Regex::Options::IGNORE_CASE)
      end
    end

    parser.on("--json", "Enable JSON pretty-printing") do
      config.json_mode = true
    end

    parser.on("-f", "--follow", "Follow file(s) (default)") do
      config.follow = true
    end

    parser.on("--no-follow", "Don't follow, just read once") do
      config.follow = false
    end

    parser.on("--no-color", "Disable ANSI colors") do
      config.no_color = true
    end

    parser.on("--since=DURATION", "Start from last N seconds (e.g., 30s, 5m, 1h)") do |duration|
      parsed = parse_duration(duration)
      unless parsed
        STDERR.puts "Error: Invalid duration format: #{duration}"
        exit 1
      end
      config.since_duration = parsed
    end

    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit 0
    end

    parser.on("-v", "--version", "Show version") do
      puts "foxtail #{Foxtail::VERSION}"
      exit 0
    end

    parser.invalid_option do |flag|
      STDERR.puts "Error: Unknown option: #{flag}"
      STDERR.puts parser
      exit 1
    end
  end

  if ARGV.empty?
    STDERR.puts "Error: No files specified"
    STDERR.puts "Usage: foxtail [options] <file...>"
    exit 1
  end

  config.files = ARGV

  app = Foxtail::FoxtailApp.new(config)
  app.run
end

main
