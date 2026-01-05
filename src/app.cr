require "json"

module Foxtail
  class FoxtailApp
    @config : Config
    @watchers : Array(FileWatcher)
    @running : Bool = true

    def initialize(@config)
      @watchers = [] of FileWatcher
      expand_files
      validate_files
      create_watchers
    end

    private def expand_files
      expanded = [] of String
      @config.files.each do |pattern|
        if pattern.includes?('*') || pattern.includes?('?') || pattern.includes?('[')
          matches = Dir.glob(pattern).to_a
          if matches.empty?
            STDERR.puts "Warning: No files match pattern '#{pattern}'"
          else
            expanded.concat(matches.sort)
          end
        else
          expanded << pattern
        end
      end
      @config.files = expanded
    end

    private def validate_files
      @config.files.each do |file|
        unless File.exists?(file)
          STDERR.puts "Warning: File '#{file}' does not exist yet, will wait for it to be created"
        end
      end

      if @config.files.empty?
        STDERR.puts "Error: No files to watch"
        exit 1
      end
    end

    private def get_color_for_file(path : String) : String
      hash = 0
      path.each_char { |c| hash += c.ord }
      COLORS[hash % COLORS.size]
    end

    private def create_watchers
      @config.files.each do |file_path|
        basename = File.basename(file_path)
        color = @config.no_color ? "" : get_color_for_file(file_path)
        @watchers << FileWatcher.new(file_path, color, basename)
      end
    end

    private def format_timestamp : String
      Time.utc.to_s("%Y-%m-%dT%H:%M:%S.%3NZ")
    end

    private def parse_json_line(line : String) : Hash(String, JSON::Any)?
      return nil unless line.starts_with?('{')
      JSON.parse(line).as_h rescue nil
    end

    private def format_json_line(data : Hash(String, JSON::Any), basename : String) : String
      level = data["level"]?.try(&.as_s) || data["severity"]?.try(&.as_s) || ""
      msg = data["msg"]?.try(&.as_s) || data["message"]?.try(&.as_s) || ""

      parts = [] of String
      parts << level.upcase if !level.empty?

      fields = data.reject { |k, _| ["level", "severity", "msg", "message", "time", "timestamp"].includes?(k) }
      fields_str = fields.map { |k, v| "#{k}=#{v}" }.join(" ")
      parts << msg if !msg.empty?
      parts << fields_str if !fields_str.empty?

      parts.join(" ")
    end

    private def format_line(line : String, basename : String, color : String) : String
      if @config.json_mode
        json_data = parse_json_line(line)
        if json_data
          content = format_json_line(json_data, basename)
        else
          content = line
        end
      else
        content = line
      end

      if @watchers.size == 1
        if @config.no_color
          content
        else
          "#{color}#{content}#{RESET}"
        end
      else
        timestamp = format_timestamp
        source = "[#{basename}]"

        if @config.no_color
          "#{timestamp} #{source} #{content}"
        else
          "#{timestamp} #{color}#{source}#{RESET} #{content}"
        end
      end
    end

    private def matches_grep?(line : String) : Bool
      pattern = @config.grep_pattern
      return true unless pattern

      pattern.matches?(line)
    end

    private def should_print?(line : String) : Bool
      return false unless matches_grep?(line)
      true
    end

    private def print_line(line : String, watcher : FileWatcher)
      return unless should_print?(line)
      puts format_line(line, watcher.@basename, watcher.@color)
    end

    private def setup_signal_handlers
      Signal::INT.trap do
        @running = false
      end

      Signal::TERM.trap do
        @running = false
      end
    end

    def run
      setup_signal_handlers

      if duration = @config.since_duration
        since_time = Time.utc - duration
        @watchers.each do |watcher|
          watcher.read_since(since_time) do |line|
            print_line(line, watcher)
          end
        end
      elsif lines = @config.lines
        @watchers.each do |watcher|
          watcher.read_last_lines(lines) do |line|
            print_line(line, watcher)
          end
        end
      elsif !@config.follow
        @watchers.each do |watcher|
          watcher.read_since(Time.utc - 365.days) do |line|
            print_line(line, watcher)
          end
        end
      else
        @watchers.each do |watcher|
          watcher.read_since(Time.utc - 365.days) do |line|
            print_line(line, watcher)
          end
        end
      end

      if @config.follow
        while @running
          @watchers.each do |watcher|
            watcher.read_new_lines do |line|
              print_line(line, watcher)
            end
          end

          flush_output
          sleep 0.05.seconds
        end
      end

      cleanup
    end

    private def flush_output
      STDOUT.flush
    end

    private def cleanup
      @watchers.each(&.close)
    end
  end
end
