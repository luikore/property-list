require_relative 'helper'

class TestLoadAscii < Test::Unit::TestCase
  def test_load_ascii
    res = PropertyList.load_ascii File.read "test/fixtures/project.pbxproj"

    # quote with escape
    assert_equal "foo 'app", res['objects']['196224331F6964760014820A']['name']

    # with slash and dot
    assert_equal 'Base.lproj/Main.storyboard', res['objects']['1962243E1F6964760014820A']['path']
  end
end
