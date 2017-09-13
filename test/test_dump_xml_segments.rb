require_relative 'helper'

class TestDumpXmlSegments < Test::Unit::TestCase
  def tag type, content
    return "<#{type}>#{content}</#{type}>\n"
  end

  def dump_segment obj
    PropertyList.dump_xml obj, segment: true
  end

  def test_string
    expected = tag('string', "&lt;Fish &amp; Chips&gt;\n\r")

    assert_equal expected, dump_segment("<Fish & Chips>\n\r")
  end

  def test_integers
    [42, 2376239847623987623, -8192].each do |i|
      assert_equal tag('integer', i), dump_segment(i)
    end
  end

  def test_floats
    [3.14159, -38.3897, 2398476293847.9823749872349980].each do |i|
      assert_equal tag('real', i), dump_segment(i)
    end
  end

  def test_floats_that_can_be_rounded
    [0.0, 4.0].each do |i|
      assert_equal tag('real', i.to_i), dump_segment(i)
    end
  end

  def test_booleans
    assert_equal "<true/>\n",  dump_segment(true)
    assert_equal "<false/>\n", dump_segment(false)
  end

  def test_time
    test_time = Time.now
    assert_equal tag('date', test_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')), dump_segment(test_time)

    test_date = Date.today
    assert_equal tag('date', test_date.strftime('%Y-%m-%dT%H:%M:%SZ')), dump_segment(test_date)

    test_datetime = DateTime.now
    assert_equal tag('date', test_datetime.strftime('%Y-%m-%dT%H:%M:%SZ')), dump_segment(test_datetime)
  end

  def test_array
    expected = <<END
<array>
	<integer>1</integer>
	<integer>2</integer>
	<integer>3</integer>
</array>
END

    assert_equal expected, dump_segment([1,2,3])
  end

  def test_empty_array
    expected = "<array/>\n"
    assert_equal expected, dump_segment([])
  end

  def test_hash
    expected = <<END
<dict>
	<key>abc</key>
	<integer>123</integer>
	<key>foo</key>
	<string>bar</string>
</dict>
END
    assert_equal expected, dump_segment({:foo => :bar, :abc => 123})
  end

  def test_empty_hash
    assert_equal "<dict/>\n", dump_segment({})
  end

  def test_hash_with_newline_in_key
    expected = <<END
<dict>
	<key>abc
def</key>
	<real>123</real>
</dict>
END
    assert_equal expected, dump_segment({"abc\ndef" => 123.0})
  end

  def test_nesting
    expected = <<END
<array>
	<dict>
		<key>foo</key>
		<array>
			<string>bar</string>
		</array>
		<key>foo2</key>
		<dict/>
	</dict>
	<string>b</string>
	<integer>3</integer>
	<array/>
</array>
END

    assert_equal expected, dump_segment([{:foo => ['bar'], :foo2 => {}}, :b, 3, []])
  end

  def test_data
    data = File.binread 'test/fixtures/finder.binary'
    str_io_res = dump_segment StringIO.new(data)
    file_io_res = File.open 'test/fixtures/finder.binary' do |f|
      dump_segment f
    end

    assert_equal str_io_res, file_io_res

    assert_equal data, Base64.decode64(str_io_res[/(?<=\>).+(?=\<)/m])
  end
end
