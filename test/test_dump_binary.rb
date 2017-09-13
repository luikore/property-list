require_relative 'helper'

class TestDumpBinary < Test::Unit::TestCase
  def dump_and_load obj
    PropertyList.load_binary PropertyList.dump_binary obj
  end

  def test_dump_set
    s = Set.new
    s << 3
    s << 'foo'
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_empty_set
    s = Set.new
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_empty_dict
    s = {}
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_empty_array
    s = []
    res = dump_and_load s
    assert_equal s, res
  end
end
