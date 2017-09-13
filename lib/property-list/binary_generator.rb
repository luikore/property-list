# encoding: binary

module PropertyList
  def self.dump_binary obj, options=nil
    generator = BinaryGenerator.new options
    generator.generate obj
    generator.output.join
  end

  # Modified from:
  #   https://github.com/jarib/plist/blob/master/lib/plist/binary.rb
  #
  # With improved performance
  class BinaryGenerator
    include BinaryMarkers

    def initialize opts
      @output = []
      @offset = 0
    end
    attr_reader :output

    # Encodes +obj+ as a binary property list. If +obj+ is an Array, Hash, or
    # Set, the property list includes its contents.
    def generate object
      flatten_objects = flatten_collection object
      ref_byte_size = min_byte_size flatten_objects.size - 1

      # Write header and encoded objects.
      # TODO use bplist10 when there are version 1x elements
      add_output "bplist00"
      offset_table = []
      flatten_objects.each do |o|
        offset_table << @offset
        binary_object o, ref_byte_size
      end

      # Write offset table.
      offset_table_addr = @offset
      offset_byte_size = min_byte_size @offset
      offset_table.each do |offset|
        binary_integer offset, offset_byte_size
      end

      # Write trailer. (6 + 2 + 24 = 32 bytes)
      add_output [
        "\0\0\0\0\0\0", # padding
        offset_byte_size, ref_byte_size,
        flatten_objects.size,
        0, # index of root object
        offset_table_addr
      ].pack("a*C2Q>3")
    end

    private

    # Takes an object (nominally a collection, like an Array, Set, or Hash, but
    # any object is acceptable) and flattens it into a one-dimensional array.
    # Non-collection objects appear in the array as-is, but the contents of
    # Arrays, Sets, and Hashes are modified like so: (1) The contents of the
    # collection are added, one-by-one, to the one-dimensional array. (2) The
    # collection itself is modified so that it contains indexes pointing to the
    # objects in the one-dimensional array. Here's an example with an Array:
    #
    #   ary = [:a, :b, :c]
    #   flatten_collection(ary) # => [[1, 2, 3], :a, :b, :c]
    #
    # In the case of a Hash, keys and values are both appended to the one-
    # dimensional array and then replaced with indexes.
    #
    #   hsh = {:a => "blue", :b => "purple", :c => "green"}
    #   flatten_collection(hsh)
    #   # => [{1 => 2, 3 => 4, 5 => 6}, :a, "blue", :b, "purple", :c, "green"]
    #
    # An object will never be added to the one-dimensional array twice. If a
    # collection refers to an object more than once, the object will be added
    # to the one-dimensional array only once.
    #
    #   ary = [:a, :a, :a]
    #   flatten_collection(ary) # => [[1, 1, 1], :a]
    #
    # The +obj_list+ and +id_refs+ parameters are private; they're used for
    # descending into sub-collections recursively.
    def flatten_collection collection, obj_list=[], id_refs={}
      case collection
      when Array, Set
        if id_refs[collection.object_id]
          return obj_list[id_refs[collection.object_id]]
        end
        obj_refs = collection.class.new
        id_refs[collection.object_id] = obj_list.length
        obj_list << obj_refs
        collection.each do |obj|
          flatten_collection(obj, obj_list, id_refs)
          obj_refs << id_refs[obj.object_id]
        end
        return obj_list

      when Hash
        if id_refs[collection.object_id]
          return obj_list[id_refs[collection.object_id]]
        end
        obj_refs = {}
        id_refs[collection.object_id] = obj_list.length
        obj_list << obj_refs
        collection.keys.sort.each do |key|
          value = collection[key]
          key = key.to_s if key.is_a?(Symbol)
          flatten_collection(key, obj_list, id_refs)
          flatten_collection(value, obj_list, id_refs)
          obj_refs[id_refs[key.object_id]] = id_refs[value.object_id]
        end
        return obj_list
      else
        unless id_refs[collection.object_id]
          id_refs[collection.object_id] = obj_list.length
          obj_list << collection
        end
        return obj_list
      end
    end

    def add_output data
      @output << data
      @offset += data.bytesize
    end

    # Returns a binary property list fragment that represents +obj+. The
    # returned string is not a complete property list, just a fragment that
    # describes +obj+, and is not useful without a header, offset table, and
    # trailer.
    #
    # The following classes are recognized: String, Float, Integer, the Boolean
    # classes, Time, IO, StringIO, Array, Set, and Hash. IO and StringIO
    # objects are rewound, read, and the contents stored as data (i.e., Cocoa
    # applications will decode them as NSData). All other classes are dumped
    # with Marshal and stored as data.
    #
    # Note that subclasses of the supported classes will be encoded as though
    # they were the supported superclass. Thus, a subclass of (for example)
    # String will be encoded and decoded as a String, not as the subclass:
    #
    #   class ExampleString < String
    #     ...
    #   end
    #
    #   s = ExampleString.new("disquieting plantlike mystery")
    #   encoded_s = binary_object(s)
    #   decoded_s = decode_binary_object(encoded_s)
    #   puts decoded_s.class # => String
    #
    # +ref_byte_size+ is the number of bytes to use for storing references to
    # other objects.
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
      when Array
        # Must be an array of object references as returned by flatten_collection.
        binary_marker MARKER_ARRAY, obj.size
        obj.each do |i|
          binary_integer i, ref_byte_size
        end
      when Set
        # Must be a set of object references as returned by flatten_collection.
        binary_marker MARKER_SET, obj.size
        obj.each do |i|
          binary_integer i, ref_byte_size
        end
      when Hash
        # Must be a table of object references as returned by flatten_collection.
        binary_marker MARKER_DICT, obj.size
        obj.keys.each do |k|
          binary_integer k, ref_byte_size
        end
        obj.values.each do |v|
          binary_integer v, ref_byte_size
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
