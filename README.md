This is a full-featured property list library which supports XML/Binary/ASCII format plists, and performance is tuned for large property list files.

The code is as clean and complete as possible. There is no runtime dependency to any other gems or libplist or other libraries.

## Install

Requires Ruby 1.9+

    gem ins property-list

## Usage

Load a plist file

    PropertyList.load_xml File.read "some_plist.xml"
    PropertyList.load_binary File.binread "some_binary.plist"
    PropertyList.load_ascii File.read "some_ascii.strings"
    PropertyList.load File.binread "unknown_format.plist"

Generate a plist file data

    PropertyList.dump_xml obj
    PropertyList.dump_binary obj
    PropertyList.dump_ascii obj

XML formatting options for `PropertyList.dump_xml object, options`

- `segment:` whether wrap the xml output is a segment or wrapped with `<?xml>` and `<plist>` tags. default is `false`.
- `xml_version:` you can also specify `"1.1"` for https://www.w3.org/TR/xml11/, default is `"1.0"`, no effect if `:segment` is set to `true`.
- `indent_unit:` the indent unit, default value is `"\t"`, set to or `''` if you don't need indent.
- `initial_indent:` initial indent space, default is `''`, the indentation per line equals to `initial_indent + indent * current_indent_level`.
- `base64_width:` the width of characters per line when serializing data with Base64, default value is `68`, must be multiple of `4`.
- `base64_indent:` whether indent the Base64 encoded data, you can use `false` for compatibility to generate same output for other frameworks, default value is `true`.

ASCII formatting options for `PropertyList.dump_ascii object, options`

- `indent_unit:` the indent unit, default value is `"\t"`, set to `''` if you don't need indent
- `initial_indent:` initial indent space, default is `''`, the indentation per line equals to `initial_indent + indent * current_indent_level`
- `wrap:` wrap the top level output with `{...}` when obj is a Hash, default is `true`.
- `encoding_comment:` add encoding comment `// !$*UTF8*$!` on top of file, default is `false`
- `sort_keys:` sort dict keys, default is `true`

## Data type mapping

Data type mapping in `PropertyList.load`:

    real:    Float
    string:  String
    integer: Integer
    data:    StringIO
    date:    DateTime
    true:    true
    false:   false
    uid:     PropertyList::Uid # obj.uid is the integer index

Reverse mapping in `PropertyList.dump_*`:

    Float:                real
    String, Symbol:       string
    Integer:              integer
    StringIO, IO:         data
    Time, DateTime, Date: date
    true:                 true
    false:                false
    PropertyList::Uid:    uid

## Credits

The binary generating code is modified from https://github.com/jarib/plist with bug fixes and performance tuning.

## Alternative plist libraries for Ruby

- [plist](https://github.com/patsplat/plist): only deals with XML plist, and generates wrong plist when there is handle line endings in strings.
- [CFPropertyList](https://github.com/ckruse/CFPropertyList): also deals with XML/Binary/ASCII plist files, more complex API and more thourough tests.
