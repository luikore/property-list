module PropertyList
  module BinaryMarkers
    # These marker bytes are prefixed to objects in a binary property list to
    # indicate the type of the object.
    MARKER_NULL           = 0b0000_0000 # v1?+ only
    MARKER_FALSE          = 0b0000_1000
    MARKER_TRUE           = 0b0000_1001
    MARKER_NO_BASE_URL    = 0b0000_1100 # followed by string, v1?+ only
    MARKER_WITH_BASE_URL  = 0b0000_1101 # followed by string, v1?+ only
    MARKER_UUID           = 0b0000_1110 # 16 byte uuid, v1?+ only
    MARKER_FILL           = 0b0000_1111 # fill byte
    MARKER_INT            = 0b0001_0000 # 0nnn
    MARKER_REAL           = 0b0010_0000 # 0nnn
    MARKER_DATE           = 0b0011_0011 # follows 8 byte big endian float

    MARKER_DATA           = 0b0100_0000 # [int]
    MARKER_ASCII_STRING   = 0b0101_0000 # [int]
    MARKER_UTF16BE_STRING = 0b0110_0000 # [int]
    MARKER_UTF8_STRING    = 0b0111_0000 # [int], v1?+ only
    MARKER_UID            = 0b1000_0000 # nnnn, followed by nnnn+1 bytes
                          # 0b1001_xxxx # unused

    MARKER_ARRAY          = 0b1010_0000
    MARKER_ORD_SET        = 0b1011_0000 # v1?+ only
    MARKER_SET            = 0b1100_0000 # v1?+ only
    MARKER_DICT           = 0b1101_0000
                          # 0b1110_xxxx # unused
                          # 0b1111_xxxx # unused

    # POSIX uses a reference time of 1970-01-01T00:00:00Z; Cocoa's reference
    # time is in 2001. This interval is for converting between the two.
    TIME_INTERVAL_SINCE_1970 = 978307200.0
  end
end
