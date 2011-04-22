module Redhead
  class Header
    attr_accessor :key, :raw, :value
    attr_writer :to_key, :to_raw
    
    def initialize(key, raw, value)
      @key = key
      @raw = raw
      @value = value
    end
    
    # Parses a string representing a header. Uses HEADER_NAME_VALUE_SEPARATOR_PATTERN
    # to determine the name and value parts of the string.
    # 
    # With a given block, the parsed raw header name is passed to the block and the result is
    # used as the key name. If no block is given, then the default is used to create the key
    # name.
    def self.parse(header_string, &block)
      header_string =~ HEADER_NAME_VALUE_SEPARATOR_PATTERN
      raw = $`
      value = $'
      
      to_key_block = block || Redhead.to_key
      key = to_key_block[raw]
      
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
    
    # Does the same thing as #to_s, but instead of calling #raw in the last case, it calls #raw!.
    def to_s!(raw_name = nil)
      r = raw_name || (block_given? ? yield(key) : raw!)
      "#{r}#{Redhead::HEADER_NAME_VALUE_SEPARATOR_CHARACTER} #{value}"
    end
    
    # Calls #to_key with #raw as the argument.
    def key!
      to_key[raw]
    end
    
    # Calls #to_raw with #key as the argument. By-passes the stored raw header name and reproduces
    # it with #to_raw dynamically.
    def raw!
      to_raw[key]
    end
    
    def inspect
      "{ #{key.inspect} => #{value.inspect} }"
    end
    
    # Returns true if other_header has the same raw header name and value as self.
    def ==(other_header)
      raw   == other_header.raw &&
      value == other_header.value
    end
    
    # Returns the Proc object used to convert keys to raw header names. Defaults to Redhead.to_raw.
    def to_raw
      @to_raw || Redhead.to_raw
    end
    
    # Returns the Proc object used to convert keys to raw header names. Defaults to Redhead.to_raw.
    def to_key
      @to_key || Redhead.to_key
    end
    
    # Returns true if to_raw[to_key[raw]] == raw, otherwise, false.
    def reversible?
      to_raw[to_key[raw]] == raw
    end
  end
end
