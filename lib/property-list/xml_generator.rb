module PropertyList

  # Generate ASCII (Plain) plist.
  #
  # Options:
  #
  # - `segment:` whether output an XML segment (not wrapped with `<?xml>, <DOCTYPE>, <plist>` tags), default is `false`.
  # - `xml_version:` you can also specify `"1.1"` for https://www.w3.org/TR/xml11/, default is `"1.0"`, no effect if `:segment` is set to `true`.
  # - `gnu_dtd:` use GNUStep DTD instead (which is a bit different in string escaping), default is `false`.
  # - `indent_unit:` the indent unit, default value is `"\t"`, set to or `''` if you don't need indent.
  # - `initial_indent:` initial indent space, default is `''`, the indentation per line equals to `initial_indent + indent * current_indent_level`.
  # - `base64_width:` the width of characters per line when serializing data with Base64, default value is `68`, must be multiple of `4`.
  # - `base64_indent:` whether indent the Base64 encoded data, you can use `false` for compatibility to generate same output for other frameworks, default value is `true`.
  #
  def self.dump_xml obj, segment: false, xml_version: '1.0', gnu_dtd: false, base64_width: 68, base64_indent: true, indent_unit: "\t", initial_indent: ''
    if !base64_width.is_a?(Integer) or base64_width <= 0 or base64_width % 4 != 0
      raise ArgumentError, "option :base64_width must be a positive integer and a multiple of 4"
    end

    generator = XmlGenerator.new gnu_dtd: gnu_dtd, base64_width: base64_width, base64_indent: base64_indent, indent_unit: indent_unit, initial_indent: initial_indent
    if segment
      generator.generate obj
    else
      generator.output << %|<?xml version="#{xml_version}" encoding="UTF-8"?>\n|
      if gnu_dtd
        generator.output << %|<!DOCTYPE plist PUBLIC "-//GNUstep//DTD plist 0.9//EN" "http://www.gnustep.org/plist-0_9.xml">\n|
        generator.output << %|<plist>\n|
      else
        generator.output << %|<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n|
        generator.output << %|<plist version="1.0">\n|
      end
      generator.generate obj
      generator.output << %|</plist>\n|
    end
    generator.output.join
  end

  class XmlGenerator #:nodoc:
    def initialize gnu_dtd: false, base64_width: 68, base64_indent: true, indent_unit: "\t", initial_indent: ''
      @gnu_dtd = gnu_dtd
      @indent_unit = indent_unit
      @indent_level = 0
      @initial_indent = initial_indent
      @indent = @initial_indent + @indent_unit * @indent_level
      @base64_bytes_per_line = (base64_width * 6) / 8
      @base64_indent = base64_indent
      @output = []
    end
    attr_reader :output

    def generate obj
      if obj.respond_to? :to_plist_xml
        xml = obj.to_plist_xml
        if !xml.start_with?(@indent)
          xml = @indent + xml
        end
        if !xml.end_with?("\n")
          xml += "\n"
        end
        @output << xml
        return
      end

      case obj
      when Array
        if obj.empty?
          empty_tag 'array'
        else
          tag 'array' do
            obj.each {|e| generate e }
          end
        end
      when Hash
        if obj.empty?
          empty_tag 'dict'
        else
          tag 'dict' do
            obj.keys.sort_by(&:to_s).each do |k|
              v = obj[k]
              tag 'key', escape_string(k.to_s)
              generate v
            end
          end
        end
      when true, false
        empty_tag obj
      when Time
        tag 'date', obj.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      when Date # also catches DateTime
        tag 'date', obj.strftime('%Y-%m-%dT%H:%M:%SZ')
      when String
        tag 'string', escape_string(obj)
      when Symbol
        tag 'string', escape_string(obj.to_s)
      when Float
        if obj.to_i == obj
          tag 'real', obj.to_i
        else
          tag 'real', obj
        end
      when Integer
        tag 'integer', obj
      when IO, StringIO
        obj.rewind
        contents = obj.read
        data_tag contents
      else
        raise UnsupportedTypeError, obj.class.to_s
      end
    end

    private

    def empty_tag name
      @output << "#@indent<#{name}/>\n"
    end

    def data_tag contents
      # m51 means: 51 bytes for each base64 encode run length, which is (51 * 8 / 6 = 68) chars per line after base64
      base64 = [contents].pack "m#@base64_bytes_per_line"
      if @base64_indent
        base64.gsub! /^/, @indent
      end
      @output << "#@indent<data>\n#{base64}#@indent</data>\n"
    end

    def tag name, contents=nil
      if block_given?
        @output << "#@indent<#{name}>\n"
        @indent = @initial_indent + @indent_unit * (@indent_level += 1)
        yield
        @indent = @initial_indent + @indent_unit * (@indent_level -= 1)
        @output << "#@indent</#{name}>\n"
      else
        @output << "#@indent<#{name}>#{contents}</#{name}>\n"
      end
    end

    TABLE_FOR_ESCAPE = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;"}.freeze
    def escape_string s
      # Likes CGI.escapeHTML but leaves `'` or `"` as mac plist does
      s = s.gsub /[&<>]/ do |c|
        TABLE_FOR_ESCAPE[c]
      end
      if @gnu_dtd
        # use \u to escape all control chars
        s.gsub(/[[:cntrl:]]/) {|c| "\\U#{c.ord.to_s(16).rjust 4, '0'}" }
      else
        s
      end
    end
  end
end
