# to helper comparison
class StringIO
  def == other
    other.is_a?(StringIO) and
    string.dup.force_encoding('binary') == other.string.dup.force_encoding('binary')
  end
end

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'test'
  end
end
require_relative '../lib/property-list'

require 'test/unit' # require it after simplecov so at_exit hook are executed in order
require 'pry'
