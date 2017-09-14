require_relative 'helper'

class TestDumpAscii < Test::Unit::TestCase
  def test_dump_ascii_date
    t = Time.now
    date = Date.new(t.year, t.month, t.day)

    ascii = PropertyList.dump_ascii date
    parsed_date = PropertyList.load_ascii ascii
    assert_equal date, parsed_date
  end

  def test_dump_ascii_data
    string = "\x00\x32={}" * 100
    string.force_encoding 'binary' if string.respond_to? :force_encoding
    data = StringIO.new string

    ascii = PropertyList.dump_ascii data
    parsed_data = PropertyList.load_ascii ascii
    assert_equal string, parsed_data.string
  end

  def test_dump_unwrapped_data
    hash = {"foo" => 'foo', 'bar' => 'bar'}
    ascii = PropertyList.dump_ascii hash, wrap: false
    expected = <<-END
bar = bar;
foo = foo;
END
    assert_equal expected, ascii
  end

  def test_unsupported_class
    assert_raise PropertyList::UnsupportedTypeError do
      PropertyList.dump_ascii PropertyList::Uid.new(12)
    end
  end

  def test_dump_symbol
    res = PropertyList.dump_ascii :"foo bar"
    assert_equal '"foo bar"', res
  end

  def test_dump_without_gnu_extension
    assert_raise PropertyList::UnsupportedTypeError do
      PropertyList.dump_ascii true, gnu_extension: false
    end
    assert_raise PropertyList::UnsupportedTypeError do
      PropertyList.dump_ascii false, gnu_extension: false
    end
    assert_raise PropertyList::UnsupportedTypeError do
      PropertyList.dump_ascii Time.now, gnu_extension: false
    end
    assert_raise PropertyList::UnsupportedTypeError do
      PropertyList.dump_ascii 3, gnu_extension: false
    end
    assert_raise PropertyList::UnsupportedTypeError do
      PropertyList.dump_ascii 3.5, gnu_extension: false
    end

    # no raise
    PropertyList.dump_ascii [{foo: 'bar'}]
  end
end
