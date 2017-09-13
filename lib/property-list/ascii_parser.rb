module PropertyList
  # Parse ASCII plist into a Ruby object
  def self.load_ascii text
    AsciiParser.new(text).parse
  end

  class AsciiParser #:nodoc:
    def initialize src
      @lexer = StringScanner.new src.strip
    end

    def parse
      res = parse_object
      skip_space_and_comment
      if !@lexer.eos? or res.nil?
        syntax_error "Unrecognized token"
      end
      res
    end

    def skip_space_and_comment
      @lexer.skip(%r{(?:
        [\x0A\x0D\u2028\u2029\x09\x0B\x0C\x20]+ # newline and space
        |
        //[^\x0A\x0D\u2028\u2029]* # one-line comment
        |
        /\*(?:.*?)\*/ # multi-line comment
      )+}mx)
    end

    def parse_object
      skip_space_and_comment
      case @lexer.peek(1)
      when '{'
        parse_dict
      when '('
        parse_array
      when '"'
        parse_string '"'
      when "'"
        parse_string "'" # NOTE: not in GNU extension
      when '<'
        parse_extension_value
      when /[\w\.\/]/
        parse_unquoted_string
      end
    end

    def parse_dict
      @lexer.pos += 1
      hash = {}
      while (skip_space_and_comment; @lexer.peek(1) != '}')
        k = \
          case @lexer.peek(1)
          when '"'
            parse_string '"'
          when "'"
            parse_string "'"
          when /\w/
            parse_unquoted_string
          end
        if !k
          syntax_error "Expect dictionary key"
        end

        skip_space_and_comment
        if !@lexer.scan(/=/)
          syntax_error "Expect '=' after dictionary key"
        end
        skip_space_and_comment

        v = parse_object
        if v.nil?
          syntax_error "Expect dictionary value"
        end

        skip_space_and_comment
        if !@lexer.scan(/;/)
          syntax_error "Expect ';' after dictionary value"
        end
        skip_space_and_comment

        hash[k] = v
      end
      if @lexer.getch != '}'
        syntax_error "Unclosed hash"
      end
      hash
    end

    def parse_array
      @lexer.pos += 1
      array = []
      while (skip_space_and_comment; @lexer.peek(1) != ')')
        obj = parse_object
        if obj.nil?
          syntax_error "Failed to parse array element"
        end
        array << obj
        skip_space_and_comment
        @lexer.scan(/,/)
      end
      if @lexer.getch != ')'
        syntax_error "Unclosed array"
      end
      array
    end

    def parse_string delim
      @lexer.pos += 1

      # TODO (TextMate only, xcode cannot parse it) when delim is ', '' is the escape

      chars = []
      while (ch = @lexer.getch) != delim
        case ch
        when '\\'
          case @lexer.getch
          when '\\'
            chars << '\\'
          when '"'
            chars << '"'
          when "'"
            chars << "'"
          when 'b'
            chars << "\b"
          when 'n'
            chars << "\n"
          when 'r'
            chars << "\r"
          when 't'
            chars << "\t"
          when 'U'
            if (hex = @lexer.scan /[0-9a-h]{4}/i)
              chars << [hex].pack('U')
            else
              syntax_error "Expect 4 digit hex code"
            end
          else
            if (oct = @lexer.scan /[0-7]{3}/)
              chars << [oct.to_i(8)].pack('U')
            else
              syntax_error "Expect 3 digit oct code"
            end
          end
        else
          chars << ch
        end
      end
      chars.join
    end

    def parse_unquoted_string
      @lexer.scan /[\w\.\/]+/
    end

    def parse_extension_value
      @lexer.pos += 1

      case @lexer.peek(2)
      when '*D' # date
        @lexer.pos += 2
        if (d = @lexer.scan /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+\-]\d{4}\>/)
          Date.strptime d.chop, "%Y-%m-%d %H:%M:%S %z"
        else
          syntax_error "Expect date value"
        end

      when '*I' # integer
        @lexer.pos += 2
        if (i = @lexer.scan /[\+\-]?\d+\>/)
          i.chop.to_i
        else
          syntax_error "Expect integer value"
        end

      when '*R' # real
        @lexer.pos += 2
        if (r = @lexer.scan /[\+\-]?\d+(\.\d+)?([eE][\+\-]?\d+)?\>/)
          r.chop.to_f
        else
          syntax_error "Expect real value"
        end

      when '*B' # boolean
        @lexer.pos += 2
        case @lexer.scan(/[YN]\>/)
        when 'Y>'
          true
        when 'N>'
          false
        else
          syntax_error "Expect boolean value"
        end

      else
        parse_data
      end
    end

    def parse_data
      if (h = @lexer.scan /[0-9a-f\s]*\>/i)
        h = h.gsub /[\s\>]/, ''
        data = [h].pack 'H*'
        StringIO.new data
      else
        syntax_error "Expect hex value"
      end
    end

    def syntax_error msg
      pre = @lexer.string[0...@lexer.pos]
      line = pre.count("\n") + 1
      col = pre.size - pre.rindex("\n")
      raise SyntaxError, msg + " at line: #{line} col: #{col} #{@lexer.inspect}", caller
    end
  end
end
