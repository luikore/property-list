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
