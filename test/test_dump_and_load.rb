require_relative 'helper'

class TestDumpAndLoad < Test::Unit::TestCase
  def test_dump_and_load
    t = Time.now
    date = Date.new(t.year, t.month, t.day).to_datetime
    data = StringIO.new "\x00\xFE"
    hash = {
      "a key with \n new line inside" => "a value with \n new line inside",
      "foo" => [
        1.0,
        2,
        true,
        false,
        date,
        data
      ]
    }

    new_hash = PropertyList.load_xml PropertyList.dump_xml hash
    assert_equal hash, new_hash

    new_hash = PropertyList.load_binary PropertyList.dump_binary hash
    assert_equal hash, new_hash

    new_hash = PropertyList.load_ascii PropertyList.dump_ascii hash
    assert_equal hash, new_hash
  end

  def test_load_and_dump_ascii
    src = File.read 'test/fixtures/project.pbxproj'
    from_ascii = PropertyList.load src
    res = PropertyList.dump_ascii from_ascii, encoding_comment: true, sort_keys: false

    cleaned_src = File.read 'test/fixtures/project.cleaned.pbxproj'
    cleaned_src.gsub! %r(/\*.*?\*/| )m, ''
    cleaned_src.gsub! /\n+/, "\n"
    res.gsub! %r(/\*.*?\*/| )m, ''
    res.gsub! /\n+/, "\n"

    line = 0
    cleaned_src.lines.zip res.lines do |expected, actual|
      assert_equal expected, actual, "at line #{line += 1}"
    end
  end

  def test_load_binary_and_dump_xml
    from_binary = PropertyList.load_binary File.binread 'test/fixtures/finder.binary'
    xml = PropertyList.dump_xml from_binary
    from_xml = PropertyList.load_xml File.read 'test/fixtures/finder.xml'

    assert_equal from_xml.keys, from_binary.keys
    assert_equal from_xml, from_binary
  end
end
