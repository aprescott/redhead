module Redhead
  class Header
    attr_accessor :key, :raw, :value

    def initialize(key, raw, value)
      @key = key
      @raw = raw
      @value = value
    end

    # Parses a string representing a header. Uses HEADER_NAME_VALUE_SEPARATOR_PATTERN
    # to determine the name and value parts of the string.
    def self.parse(header_string)
      header_string =~ HEADER_NAME_VALUE_SEPARATOR_PATTERN
      raw = $`
      value = $'
      key = TO_KEY[raw]

      header = new(key, raw, value)

      header
    end

    # Returns the header as a string. If raw_name is given, this value is used as the raw header
    # name. If raw_name is not given, do one of two things:
    # 
    # * If a block is given, pass #key to the block and use the result as the raw header name.
    # * If a block is not given, use #raw as the raw header name.
    def to_s(raw_name = nil)
      r = raw_name || (block_given? ? yield(key) : raw)
      "#{r}#{Redhead::HEADER_NAME_VALUE_SEPARATOR_CHARACTER} #{value}"
    end

    # Does the same thing as #to_s, but instead of calling #raw in the last case, it computes the
    # raw header name dynamically from the key.
    def to_s!(raw_name = nil)
      r = raw_name || (block_given? ? yield(key) : TO_RAW[key])
      "#{r}#{Redhead::HEADER_NAME_VALUE_SEPARATOR_CHARACTER} #{value}"
    end

    def inspect
      "{ #{key.inspect} => #{value.inspect} }"
    end

    # Returns true if other_header has the same raw header name and value as self.
    def ==(other_header)
      raw   == other_header.raw &&
      value == other_header.value
    end
  end
end
