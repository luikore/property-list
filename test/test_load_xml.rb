require_relative 'helper'

class TestLoadXml < Test::Unit::TestCase
  def tag type, content
    return "<#{type}>#{content}</#{type}>\n"
  end

  def test_decode_entities
    data = PropertyList.load_xml('<string>Fish &amp; Chips</string>')
    assert_equal('Fish & Chips', data)
  end

  def test_comment_handling_and_empty_plist
    assert_nil PropertyList.load_xml(File.read 'test/fixtures/commented.xml')
    assert_nil PropertyList.load_xml(File.read 'test/fixtures/empty.xml')
  end

  def test_syntax_error
    assert_raises PropertyList::SyntaxError do
      PropertyList.load_xml "<plist><string>341</integer></plist>"
    end
  end

  def test_load_empty_dict
    assert_equal ({}), PropertyList.load_xml('<dict />')
  end
end
