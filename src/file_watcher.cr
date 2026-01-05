module Foxtail
  class FileWatcher
    @file_path : String
    @file : File?
    @last_pos : UInt64 = 0
    @last_mtime : Time?
    @last_size : UInt64 = 0
    @buffered_line = ""
    @color : String
    @basename : String

    def initialize(@file_path, @color, @basename)
      open_file
    end

    private def open_file
      @file.try(&.close) if @file

      if File.exists?(@file_path)
        @file = File.open(@file_path, "r")
        stat = File.info(@file_path)
        mtime = stat.modification_time
        size = stat.size.to_u64

        @last_mtime = mtime
        @last_size = size

        if size < @last_pos
          @last_pos = 0
        end

        @file.not_nil!.seek(@last_pos) if @last_pos > 0
      else
        @file = nil
        @last_pos = 0
        @last_mtime = nil
        @last_size = 0
      end
    end

    private def check_rotation
      return unless File.exists?(@file_path)

      stat = File.info(@file_path)
      current_size = stat.size.to_u64

      if current_size < @last_pos
        @last_pos = 0
        open_file
      end
    end

    def read_new_lines(&block : String ->)
      check_rotation

      file = @file
      return unless file

      while char = file.read_char
        if char == '\n'
          if @buffered_line.size > 0
            yield @buffered_line
            @buffered_line = ""
          end
        elsif char == '\r'
        else
          @buffered_line += char
        end
      end

      @last_pos = file.pos.to_u64
    end

    def read_since(since_time : Time, &block : String ->)
      open_file
      file = @file
      return unless file

      file.each_line do |line|
        yield line
      end

      @last_pos = file.pos.to_u64
    end

    def read_last_lines(count : Int32, &block : String ->)
      open_file
      file = @file
      return unless file

      lines = [] of String
      file.each_line do |line|
        lines << line
        if lines.size > count
          lines.shift
        end
      end

      lines.each { |line| yield line }
      @last_pos = file.pos.to_u64
    end

    def close
      @file.try(&.close)
    end
  end
end
