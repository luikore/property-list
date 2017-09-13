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

  class UID
    def initialize uid
      @uid = uid
    end
    attr_reader :uid
  end

  # binary plist v1x elements:

  class URL
    def initialize url
      @url = url
    end
    attr_reader :url
  end

  class UUID
    def initialize uuid
      @uuid = uuid
    end
    attr_reader :uuid
  end

  class OrderedSet
    def initialize elements
      @elements = elements.uniq
    end

    def each
      @elements.each do |e|
        yield e
      end
    end
  end
end
