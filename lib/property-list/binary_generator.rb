# encoding: binary

module PropertyList
  # Generate binary plist, the version is auto detected
  def self.dump_binary obj, options=nil
    generator = BinaryGenerator.new options
    generator.generate obj
    generator.output.join
  end

  # Modified from:
  #   https://github.com/jarib/plist/blob/master/lib/plist/binary.rb
  #
  # With improved performance
  class BinaryGenerator #:nodoc:
    include BinaryMarkers

    Collection = Struct.new :marker, :size, :refs

    def initialize opts
      @output = []
      @offset = 0
      @objs = []
      @ref_size = 0
    end
    attr_reader :output

    def generate obj
      flatten obj
      ref_byte_size = min_byte_size @ref_size - 1

      add_output "bplist00"
      offset_table = []
      @objs.each do |o|
        offset_table << @offset
        binary_object o, ref_byte_size
      end

      offset_table_addr = @offset
      offset_byte_size = min_byte_size @offset
      offset_table.each do |offset|
        binary_integer offset, offset_byte_size
      end

      add_output [
        "\0\0\0\0\0\0", # padding
        offset_byte_size, ref_byte_size,
        @ref_size,
        0, # index of root object
        offset_table_addr
      ].pack("a*C2Q>3")
    end

    def flatten obj
      @ref_size += 1

      case obj
      when Array
        refs = []
        @objs << Collection[MARKER_ARRAY, obj.size, refs]
        obj.each do |e|
          refs << @ref_size
          flatten e
        end

      when Set
        refs = []
        @objs << Collection[MARKER_SET, obj.size, refs]
        obj.each do |e|
          refs << @ref_size
          flatten e
        end

      when Hash
        refs = []
        @objs << Collection[MARKER_DICT, obj.size, refs]
        obj.each do |e, _|
          refs << @ref_size
          flatten e
        end
        obj.each do |_, e|
          refs << @ref_size
          flatten e
        end

      else
        @objs << obj
      end
    end

    def add_output data
      @output << data
      @offset += data.bytesize
    end

    def binary_object obj, ref_byte_size = 4
      case obj
      when Symbol
        binary_string obj.to_s
      when String
        binary_string obj
      when URL
        binary_url obj.url
      when Float
        add_output [(MARKER_REAL | 3), obj].pack("CG")
      when Integer
        nbytes = min_byte_size obj
        size_bits = { 1 => 0, 2 => 1, 4 => 2, 8 => 3, 16 => 4 }[nbytes]
        add_output (MARKER_INT | size_bits).chr
        binary_integer obj, nbytes
      when TrueClass
        add_output MARKER_TRUE.chr
      when FalseClass
        add_output MARKER_FALSE.chr
      when Time
        add_output [MARKER_DATE, obj.to_f - TIME_INTERVAL_SINCE_1970].pack("CG")
      when Date # also covers DateTime
        add_output [MARKER_DATE, obj.to_time.to_f - TIME_INTERVAL_SINCE_1970].pack("CG")
      when IO, StringIO
        obj.rewind
        obj.binmode
        data = obj.read
        binary_marker MARKER_DATA, data.bytesize
        add_output data
      when Collection
        binary_marker obj.marker, obj.size
        obj.refs.each do |i|
          binary_integer i, ref_byte_size
        end
      else
        raise "Unsupported class: #{obj.class}"
      end
    end

    def binary_marker marker, size
      if size < 15
        add_output (marker | size).chr
      else
        add_output (marker | 0xf).chr
        binary_object size
      end
    end

    def binary_string obj
      if obj.encoding == Encoding.find('binary')
        binary_marker MARKER_ASCII_STRING, obj.bytesize
        add_output obj
      elsif obj.ascii_only?
        obj = obj.dup.force_encoding 'binary'
        binary_marker MARKER_ASCII_STRING, obj.bytesize
        add_output obj
      else
        data = obj.encode('utf-16be').force_encoding 'binary'
        cp_size = data.bytesize / 2
        binary_marker MARKER_UTF16BE_STRING, cp_size # TODO check if it works for 4 bytes
        add_output data
      end
    end

    def binary_url obj
      @v1 = true
      if obj =~ /\A\w+:/
        add_output MARKER_WITH_BASE_URL.chr
      else
        add_output MARKER_NO_BASE_URL.chr
      end
      binary_marker MARKER_ASCII_STRING, obj.bytesize
      add_output obj
    end

    def binary_uuid obj
      # TODO
    end

    def binary_ordered_set obj
      # TODO
    end

    # Packs an integer +i+ into its binary representation in the specified
    # number of bytes. Byte order is big-endian. Negative integers cannot be
    # stored in 1, 2, or 4 bytes.
    def binary_integer i, num_bytes
      if i < 0 && num_bytes < 8
        raise ArgumentError, "negative integers require 8 or 16 bytes of storage"
      end
      case num_bytes
      when 1
        add_output [i].pack("C")
      when 2
        add_output [i].pack("n")
      when 4
        add_output [i].pack("N")
      when 8
        add_output [i].pack("q>")
      when 16
        # TODO verify 128 bit integer encoding
        if i < 0
          i = 0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff ^ i.abs + 1
        end
        add_output [i >> 64, i & 0xffff_ffff_ffff_ffff].pack("q>2")
      else
        raise ArgumentError, "num_bytes must be 1, 2, 4, 8, or 16"
      end
    end

    # Determines the minimum number of bytes that is a power of two and can
    # represent the integer +i+. Raises a RangeError if the number of bytes
    # exceeds 16. Note that the property list format considers integers of 1,
    # 2, and 4 bytes to be unsigned, while 8- and 16-byte integers are signed;
    # thus negative integers will always require at least 8 bytes of storage.
    def min_byte_size i
      if i < 0
        i = i.abs - 1
      else
        if i <= 0xff
          return 1
        elsif i <= 0xffff
          return 2
        elsif i <= 0xffffffff
          return 4
        end
      end      
      if i <= 0x7fffffffffffffff
        8
      elsif i <= 0x7fffffffffffffffffffffffffffffff
        16
      else
        raise RangeError, "integer too big - exceeds 128 bits"
      end
    end
  end
end
