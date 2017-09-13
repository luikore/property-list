require_relative 'helper'

class TestDumpXmlFormatting < Test::Unit::TestCase
  def test_custom_base64_format
    hash = {:key1 => StringIO.new('f' * 41)}
    actual = PropertyList.dump_xml(hash, :segment => true, :base64_width => 16, :base64_indent => false)
    expected = <<-STR
<dict>
	<key>key1</key>
	<data>
ZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZm
ZmZmZmY=
	</data>
</dict>
STR
    assert_equal expected, actual

    actual = PropertyList.dump_xml(hash, :segment => true, :base64_width => 12, :base64_indent => false)
    expected = <<-STR
<dict>
	<key>key1</key>
	<data>
ZmZmZmZmZmZm
ZmZmZmZmZmZm
ZmZmZmZmZmZm
ZmZmZmZmZmZm
ZmZmZmY=
	</data>
</dict>
STR
    assert_equal expected, actual

    assert_raises ArgumentError do
      PropertyList.dump_xml(hash, :segment => true, :base64_width => 17, :base64_indent => true)
    end
  end

  def test_custom_indent
    hash = { :key1 => 1, 'key2' => [3] }

    actual = PropertyList.dump_xml(hash, :indent_unit => '   ')
    expected = <<-STR
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>key1</key>
   <integer>1</integer>
   <key>key2</key>
   <array>
      <integer>3</integer>
   </array>
</dict>
</plist>
STR
    assert_equal expected, actual

    actual = PropertyList.dump_xml(hash, :segment => true, :indent_unit => '   ', :initial_indent => "\t")
    expected = <<-STR
	<dict>
	   <key>key1</key>
	   <integer>1</integer>
	   <key>key2</key>
	   <array>
	      <integer>3</integer>
	   </array>
	</dict>
STR
    assert_equal expected, actual
  end
end
