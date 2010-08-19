module Wrong
  class Chunk
    def self.from_block(block, depth = 0)
      file, line = if block.to_proc.respond_to? :source_location
                     block.to_proc.source_location
                   else
                     caller[depth].split(":")
                   end
      new(file, line)
    end

    def initialize(file, line)
      @file = file
      @line = line.to_i - 1
    end

    def sexp
      @sexp ||= begin
        lines = File.read(@file).split("\n")
        parser = RubyParser.new
        c = 0
        sexp = nil
        while sexp.nil? && @line + c < lines.size
          begin
            @chunk = lines[@line..@line+c].join("\n")
            sexp = parser.parse(@chunk)
          rescue Racc::ParseError => e
            # loop and try again
            c += 1
          end
        end
        if sexp.nil?
          raise "Could not parse #{@file}:#{@line}"
        else
          # find the "assert" and its block
          assertion = if sexp.assertion?
            sexp
          else
            # todo: move into sexp
            assertions = []
            sexp.each_of_type(:iter) { |sexp| assertions << sexp if sexp.assertion? }
            assertions.first
          end

          statement = assertion && assertion[3]
          if statement.nil?
            raise "Could not find assertion block in #{@file}:#{@line}\n\t#{@chunk.strip}\n\t#{sexp}"
          else
            statement
          end
        end
      end
    end

    def code
      self.sexp.to_ruby
    end

    def parts(sexp = nil)
      if sexp.nil?
        parts(self.sexp).compact.uniq
      else
        p = []
        begin
          code = sexp.to_ruby.strip
          p << code unless code == ""
        rescue => e
          puts "#{e.class}: #{e.message}"
          puts e.backtrace.join("\n")
        end
        sexp.each do |sub|
          if sub.is_a?(Sexp)
            p += parts(sub)
            # else
            #   puts "#{o.inspect} is a #{o.class}"
          end
        end
        p
      end
    end

  end

end
# todo: move to monkey patch file
class Sexp < Array
  def doop
    Marshal.load(Marshal.dump(self))
  end

  def to_ruby
    d = self.doop
    x = Ruby2Ruby.new.process(d)
    x
  end

  def assertion?
    self.is_a? Sexp and
    self[0] == :iter and
    self[1].is_a? Sexp and
    self[1][0] == :call and
    [:assert, :deny].include? self[1][2] # todo: allow aliases for assert (e.g. "is")
  end
end
