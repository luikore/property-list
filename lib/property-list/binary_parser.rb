module PropertyList
  def self.load_binary(data)
    BinaryParser.new(data).parse
  end

  # Reference:
  #   https://opensource.apple.com/source/CF/CF-1151.16/CFBinaryPList.c.auto.html
  class BinaryParser
    include BinaryMarkers

    def initialize src
      @src = src

      @offset_byte_size, @ref_byte_size, @flatten_objects_size, @root_object_index, @offset_table_addr = \
        @src.byteslice((-32)..(-1)).unpack '@6C2Q>3'
    end

    def parse
      @offset_table = decode_offset_table
      decode_id @root_object_index
    end

    private

    def decode_object offset
      first_byte, = @src.unpack "@#{offset}C"
      marker = first_byte & 0xF0
      if marker == 0 or first_byte == MARKER_DATE
        marker = first_byte
      end

      case marker
      when MARKER_NULL
        nil
      when MARKER_FALSE
        false
      when MARKER_TRUE
        true
      when MARKER_NO_BASE_URL
        raise 'todo'
      when MARKER_WITH_BASE_URL
        raise 'todo'
      when MARKER_UUID
        raise 'todo'
      when MARKER_FILL
        decode_object offest + 1
      when MARKER_INT
        size_bits = first_byte & 0x0F
        num_bytes = 2 ** size_bits
        decode_integer offset + 1, num_bytes
      when MARKER_REAL
        r, = @src.unpack "@#{offset + 1}G"
        r
      when MARKER_DATE
        seconds_since_2001, = @src.unpack "@#{offset + 1}G"
        Time.at(TIME_INTERVAL_SINCE_1970 + seconds_since_2001).to_datetime
      when MARKER_DATA
        data = @src.byteslice *(decode_vl_info offset)
        StringIO.new data
      when MARKER_ASCII_STRING
        @src.byteslice *(decode_vl_info offset)
      when MARKER_UTF16BE_STRING
        str_offset, str_size = decode_vl_info offset
        s = @src.byteslice str_offset, str_size * 2
        s.force_encoding('utf-16be').encode 'utf-8'
      when MARKER_UTF8_STRING
        s = @src.byteslice *(decode_vl_info offset)
        s.force_encoding 'utf-8'
      when MARKER_UID
        # Encoding is as integers, except values are unsigned.
        # These are used extensively in files written using NSKeyedArchiver, a serializer for Objective-C objects.
        # The value is the index in parse_result["$objects"]
        size = (first_byte & 0xF) + 1
        bytes = @src.byteslice offset + 1, size
        res = 0
        bytes.unpack('C*').each do |byte|
          res *= 256
          res += byte
        end
        UID[res]
      when MARKER_ARRAY
        offset, size = decode_vl_info offset
        size.times.map do |i|
          id = decode_ref_id offset + i * @ref_byte_size
          decode_id id
        end
      when MARKER_ORD_SET, MARKER_SET
        r = Set.new
        offset, size = decode_vl_info offset
        size.times do |i|
          id = decode_ref_id offset + i * @ref_byte_size
          r << (decode_id id)
        end
        r
      when MARKER_DICT
        offset, size = decode_vl_info offset
        keys_byte_size = @ref_byte_size * size
        entries = []
        size.times do |i|
          k_offset = offset + i * @ref_byte_size
          v_offset = k_offset + keys_byte_size
          entries << [
            decode_id(decode_ref_id k_offset),
            decode_id(decode_ref_id v_offset)
          ]
        end
        entries.sort_by! &:first
        Hash[entries]
      else
        raise "unused marker: 0b#{marker.to_s(2).rjust 8, '0'}"
      end
    end

    def decode_vl_info offset
      marker, = @src.unpack "@#{offset}C"
      vl_size_bits = marker & 0x0F

      if vl_size_bits == 0x0F
        # size is followed by marker int
        int_marker, = @src.unpack "@#{offset + 1}C"
        num_bytes = 2 ** (int_marker & 0x0F)
        size = decode_integer offset + 2, num_bytes
        [offset + 2 + num_bytes, size]
      else
        [offset + 1, vl_size_bits]
      end
    end

    def decode_offset_table
      @flatten_objects_size.times.map do |i|
        offset_index = @offset_table_addr + i * @offset_byte_size
        decode_integer offset_index, @offset_byte_size
      end
    end

    # decode the i-th entry in offset table
    def decode_id i
      raise "ref-id should be positive, but got #{i}" if i < 0
      offset = @offset_table[i]
      raise "offset not found for ref-id #{i}" if !offset
      decode_object offset
    end

    # decode integer of ref byte size
    def decode_ref_id offset
      decode_integer offset, @ref_byte_size
    end

    def decode_integer offset, num_bytes
      # NOTE: only num_bytes = 8 or 16 it can be negative
      case num_bytes
      when 1
        i, = @src.unpack "@#{offset}C"
      when 2
        i, = @src.unpack "@#{offset}n"
      when 4
        i, = @src.unpack "@#{offset}N"
      when 8
        i, = @src.unpack "@#{offset}q>"
      when 16
        hi, lo = @src.unpack "@#{offset}q>2"
        i = (hi << 64) | lo
      else
        raise ArgumentError, "num_bytes must be 1, 2, 4, 8, or 16"
      end
      i
    end
  end
end
