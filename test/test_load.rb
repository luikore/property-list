require_relative 'helper'

class TestLoad < Test::Unit::TestCase
  def test_load_xml_equals_load_binary
    a = PropertyList.load File.read 'test/fixtures/finder.xml'
    b = PropertyList.load File.binread 'test/fixtures/finder.binary'
    assert_equal a.keys, b.keys

    a.each do |k, av|
      bv = b[k]
      assert_equal av, bv, "value of #{k}"
    end
  end
end
