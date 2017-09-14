module PropertyList
  # Parse XML plist into a Ruby object
  def self.load_xml xml
    XmlParser.new(xml).parse
  end

  class XmlParser #:nodoc:
    def initialize src
      @lexer = StringScanner.new src
    end

    def skip_space_and_comments
      @lexer.skip(%r{(?:
        [\x0A\x0D\u2028\u2029\x09\x0B\x0C\x20]+ # newline and space
        |
        <!--(?:.*?)-->
      )+}mx)
    end

    def parse
      @lexer.skip(/<\?xml\s+.*?\?>*/m)
      # TODO xml_encoding = xml_declaration.match(/(?:\A|\s)encoding=(?:"(.*?)"|'(.*?)')(?:\s|\Z)/)

      skip_space_and_comments
      @lexer.skip(/\s*<!DOCTYPE\s+.*?>/m)
      skip_space_and_comments

      if @lexer.scan(/<plist\s*\b[^\/\>]*\/>/)
        skip_space_and_comments
        if !@lexer.eos?
          syntax_error "unrecognized code after plist tag end"
        end
        return
      end

      plist_open = !!@lexer.scan(/<plist\s*\b.*?(?<!\/)>/m)

      res = parse_object

      skip_space_and_comments
      plist_close = !!@lexer.scan(/<\/plist\s*>/m)
      skip_space_and_comments
      if !@lexer.eos?
        syntax_error "unrecognized code after plist tag end"
      end

      if plist_open ^ plist_close
        syntax_error "mismatched <plist> tag"
      end

      res
    end

    # pushes obj into stack
    def parse_object
      skip_space_and_comments
      if e = @lexer.scan(/<(true|false|array|dict|data)\s*\/>/m)
        case e[/\w+/]
        when 'true'; true
        when 'false'; false
        when 'array'; []
        when 'dict'; {}
        else; '' # data
        end

      elsif e = @lexer.scan(/<(integer|real|string|date|data)\s*>[^<>]*<\/\1\s*>/m)
        tag = e[/\w+/]
        content = tag_content e

        case tag
        when 'integer'
          content.to_i
        when 'real'
          content.to_f
        when 'string'
          CGI.unescape_html content
        when 'date'
          DateTime.parse content
        else # data
          StringIO.new Base64.decode64 content
        end

      elsif e = @lexer.scan(/<array\s*>/m)
        res = []
        until (skip_space_and_comments; @lexer.scan(/<\/array\s*>/m))
          e = parse_object
          syntax_error 'failed to parse array element' if e.nil?
          res << e
        end
        res

      elsif e = @lexer.scan(/<dict\s*>/)
        res = {}
        until (skip_space_and_comments; @lexer.scan(/<\/dict\s*>/m))
          key_tag = @lexer.scan(/<key\s*>[^<>]*<\/key\s*>/m)
          syntax_error 'failed to parse dict key' if !key_tag

          key = CGI.unescape_html tag_content key_tag
          value = parse_object
          syntax_error 'failed to parse dict value' if value.nil?
          res[key] = value
        end
        res

      else
        nil
      end
    end

    def tag_content e
      e[(e.index('>') + 1)...(e.rindex '<')]
    end

    def syntax_error msg
      pre = @lexer.string[0...@lexer.pos]
      line = pre.count("\n") + 1
      col = pre.size - (pre.rindex("\n") || -1)
      raise SyntaxError, msg + " at line: #{line} col: #{col} #{@lexer.inspect}", caller
    end
  end
end
