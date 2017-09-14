require_relative 'helper'

class TestLoadAscii < Test::Unit::TestCase
  def test_load_ascii
    res = PropertyList.load_ascii File.read "test/fixtures/project.pbxproj"

    # quote with escape
    assert_equal "foo 'app", res['objects']['196224331F6964760014820A']['name']

    # with slash and dot
    assert_equal 'Base.lproj/Main.storyboard', res['objects']['1962243E1F6964760014820A']['path']
  end

  def test_load_string_oct_hex_escape
    s = "\123\u{3F4A}"
    res = PropertyList.load_ascii '"\123\U3F4A"'
    assert_equal s, res
  end

  def test_load_string_escape
    s = "\t\n\r\b\\\""
    res = PropertyList.load_ascii '"\t\n\r\b\\\\\""'
    assert_equal s, res
  end

  def test_load_string_bad_unicode
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '\U123G'
    end
  end

  def test_load_string_bad_escape
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '"\i"'
    end
    begin
      PropertyList.load_ascii '"\i"'
    rescue
      assert $!.message.include?('Bad escape'), $!.message
    end
  end

  def test_bad_token
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '\i'
    end
    begin
      PropertyList.load_ascii '\i'
    rescue
      assert $!.message.include?('Unrecognized token'), $!.message
    end
  end

  def test_load_incomplete_boolean
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '<*B'
    end
  end

  def test_load_incomplete_data
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '<F'
    end
  end

  def test_load_bad_integer
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '<*IF>'
    end
  end

  def test_load_bad_real
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '<*R3.3.3>'
    end
  end

  def test_load_bad_date
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '<*D102347>'
    end
  end

  def test_unclosed_array
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '(foo'
    end
  end

  def test_unclosed_dict
    assert_raise PropertyList::SyntaxError do
      PropertyList.load_ascii '{foo = bar;'
    end
  end
end
