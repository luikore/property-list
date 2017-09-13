module PropertyList
  # options can be:
  #
  # [:indent_unit] the indent unit, default value is <code>"\t"</code>, set to <code>''</code> if you don't need indent
  #
  # [:initial_indent] initial indent space, default is <code>''</code>, the indentation per line equals to <code>initial_indent + indent * current_indent_level</code>
  #
  # [:wrap] wrap the top level output with '{}' when obj is a Hash, default is true.
  #
  # [:encoding_comment] add encoding comment '!$*UTF8*$!' on top of file, default is false
  #
  # [:sort_keys] sort dict keys, default is true
  #
  def self.dump_ascii obj, indent_unit: "\t", initial_indent: '', wrap: true, encoding_comment: false, sort_keys: true
    generator = AsciiGenerator.new indent_unit: indent_unit, initial_indent: initial_indent, sort_keys: sort_keys
    generator.output << "// !$*UTF8*$!\n" if encoding_comment
    generator.generate obj, wrap
    generator.output << "\n" if wrap and obj.is_a?(Hash)
    generator.output.join
  end

  class AsciiGenerator #:nodoc:
    def initialize indent_unit: "\t", initial_indent: '', sort_keys: true
      @indent_unit = indent_unit
      @indent_level = 0
      @initial_indent = initial_indent
      @indent = @initial_indent + @indent_unit * @indent_level
      @sort_keys = sort_keys
      @output = []
    end
    attr_reader :output

    def generate object, wrap=true
      # See also
      # http://www.gnustep.org/resources/documentation/Developer/Base/Reference/NSPropertyList.html
      # The <...> extensions are from GNUStep

      case object
      when Array
        ascii_collection '(', ')' do
          object.each do |e|
            generate e
            @output << ",\n"
          end
        end
      when Hash
        if wrap
          ascii_collection '{', '}' do
            ascii_hash_content object
          end
        else
          ascii_hash_content object
        end
      when true
        ascii_value "<*BY>"
      when false
        ascii_value "<*BN>"
      when Float
        if object.to_i == object
          object = object.to_i
        end
        ascii_value "<*R#{object}>"
      when Integer
        ascii_value "<*I#{object}>"
      when Time, Date # also covers DateTime
        ascii_value "<*D#{object.strftime '%Y-%m-%d %H:%M:%S %z'}>"
      when String
        ascii_string object
      when Symbol
        ascii_string object.to_s
      when IO, StringIO
        object.rewind
        contents = object.read
        ascii_data contents
      else
        raise "Generating of this class is not supported"
      end
    end

    def ascii_value v
      @output << @indent
      @output << v
    end

    TABLE_FOR_ASCII_STRING_ESCAPE = {
      "\\".ord => "\\\\",
      '"'.ord => '\\"',
      "\b".ord => '\b',
      "\n".ord => "\\n",
      "\r".ord => "\\r",
      "\t".ord => "\\t"
    }.freeze
    def ascii_string s
      @output << @indent

      if s =~ /\A[\w\.\/]+\z/
        @output << s
        return
      end

      # there is also single quote string, in which we can use new lines and '' for single quote
      @output << '"'
      s.unpack('U*').each do |c|
        if c > 127
          # there is also a \OOO format, but we only generate the \U format
          @output << "\\U#{c.to_s(16).rjust 4, '0'}"
        elsif (escaped_c = TABLE_FOR_ASCII_STRING_ESCAPE[c])
          @output << escaped_c
        else
          @output << c.chr
        end
      end
      @output << '"'
    end

    def ascii_collection start_delim, end_delim
      @output << @indent
      @output << start_delim
      @output << "\n"
      @indent = @initial_indent + @indent_unit * (@indent_level += 1)
      yield
      @indent = @initial_indent + @indent_unit * (@indent_level -= 1)
      @output << @indent
      @output << end_delim
    end

    def ascii_hash_content object
      keys = object.keys
      keys.sort_by! &:to_s if @sort_keys
      keys.each do |k|
        v = object[k]
        reset_indent = @indent
        ascii_string k.to_s
        @output << ' = '
        @indent = '' # ignores the indent for first line
        generate v
        @output << ";\n"
        @indent = reset_indent
      end
    end

    def ascii_data content
      hex, _ = content.unpack 'H*'
      hex.gsub! /(.{2})/, "\\1 "
      @output << "< #{hex}>"
    end
  end
end
