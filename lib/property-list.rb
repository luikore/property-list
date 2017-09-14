require 'date'
require 'set'
require 'base64'
require 'cgi'
require 'stringio'
require 'strscan'

require_relative 'property-list/xml_generator'
require_relative 'property-list/xml_parser'
require_relative 'property-list/ascii_generator'
require_relative 'property-list/ascii_parser'
require_relative 'property-list/binary_markers'
require_relative 'property-list/binary_generator'
require_relative 'property-list/binary_parser'
require_relative 'property-list/version'

module PropertyList
  # Load plist from file
  #
  # Auto detects format
  def self.load_file file_name
    load File.binread file_name
  end

  # Load plist (binary or xml or ascii) into a ruby object.
  #
  # Auto detects format.
  def self.load data
    case data.byteslice(0, 8)
    when /\Abplist\d\d/n
      load_binary data.force_encoding('binary')
    when /\A<\?xml\ /n
      load_xml data.force_encoding('utf-8')
    else
      load_ascii data.force_encoding('utf-8')
    end
  end

  class SyntaxError < RuntimeError
  end

  class UnsupportedTypeError < RuntimeError
  end

  # binary plist v0x elements:

  # These are used extensively in files written using NSKeyedArchiver, a serializer for Objective-C objects.
  # The value is the index in parse_result["$objects"]
  #
  # call-seq:
  #
  #     PropertyList::Uid.new 34
  class Uid
    def initialize uid
      @uid = uid
    end

    attr_reader :uid

    def == other
      other.is_a?(Uid) and @uid == other.uid
    end
  end

  # binary plist v1x elements:

  # call-seq:
  #
  #     PropertyList::Url.new 'http://foo.com' # with base
  #     PropertyList::Url.new '/foo.com'       # no base
  class Url
    def initialize url
      @url = url
    end

    attr_reader :url

    def == other
      other.is_a?(Url) and @url == other.url
    end
  end

  # call-seq:
  #
  #     PropertyList::Uuid.new 'F' * 32
  class Uuid
    def initialize uuid
      @uuid = uuid
    end

    attr_reader :uuid

    def == other
      other.is_a?(Uuid) and @uuid == other.uuid
    end
  end

  # call-seq:
  #
  #     PropertyList::OrdSet.new ['foo', 'bar', 3, 4]
  class OrdSet
    def initialize elements
      @elements = elements.uniq
    end

    attr_reader :elements

    def == other
      other.is_a?(OrdSet) and @elements == other.elements
    end
  end
end
