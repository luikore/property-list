require_relative 'helper'

class TestDumpBinary < Test::Unit::TestCase
  def dump_and_load obj
    PropertyList.load_binary PropertyList.dump_binary obj
  end

  def test_dump_binary_string
    s = "\x03\x00".force_encoding 'binary'
    res = dump_and_load s
    assert_equal s, res.force_encoding('binary')
  end

  def test_dump_unicode_string
    s = "𝄞"
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_symbol
    str_res = PropertyList.dump_binary 'foo'
    sym_res = PropertyList.dump_binary :foo
    assert_equal str_res, str_res
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

  def test_dump_uid
    s = PropertyList::Uid.new 10234
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_uuid
    s = PropertyList::Uuid.new "FA" * 16
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_ord_set
    s = PropertyList::OrdSet.new ['foo', 'bar']
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_url
    s = PropertyList::Url.new 'http://foo.com'
    res = dump_and_load s
    assert_equal s, res

    s = PropertyList::Url.new '/foo.com'
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_nil
    res = dump_and_load nil
    assert_equal nil, res
  end

  def test_dump_4bytes_int
    s = 1 << 30
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_4bytes_negative_int
    s = -(1 << 30)
    res = dump_and_load s
    assert_equal s, res
  end

  def test_dump_8bytes_negative_int
    s = -(1 << 56)
    res = dump_and_load s
    assert_equal s, res
  end

  def test_unsupported_class
    assert_raise PropertyList::UnsupportedTypeError do
      PropertyList.dump_binary(/foo/)
    end
  end

  def test_dump_time
    t = Time.at Time.now.to_i
    res = dump_and_load(t).to_time
    assert_equal t, res
  end
end
