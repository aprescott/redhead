module Redhead
  class HeaderSet
    include Enumerable
    
    # Sets the headers of the set to _headers_. _headers_ is assumed to be ordered.
    def initialize(headers)
      @headers = headers
    end
    
    # Parses lines of header strings with Header.parse. Returns a new HeaderSet object
    # for the parsed headers.
    def self.parse(header_string, &block)
      headers = []
      header_string.split("\n").each do |str|
        headers << Redhead::Header.parse(str, &block)
      end
      
      new(headers)
    end
    
    # Yields each header in the set.
    def each
      @headers.each { |h| yield h }
    end
    
    # Returns true if the set of headers is empty.
    def empty?
      @headers.empty?
    end
    
    # Returns the first header found which has Header#key matching _key_.
    def [](key)
      @headers.find { |header| header.key == key }
    end
    
    # If there is a header in the set with a key matching _key_, then set its value to _value_.
    # If there is no header matching _key_, create a new header with the given key and value,
    # with a raw header equal to to_raw[key]. Sets the new header's to_raw to self#to_raw.
    def []=(key, value)
      h = self[key]      
      if h
        h.value = value
      else
        new_header = Redhead::Header.new(key, to_raw[key], value)
        new_header.to_raw = to_raw
        self << new_header
      end
    end
    
    # Adds _header_ to the set of headers.
    def <<(header)
      @headers << header
    end
    
    # Similar to #[]= but allows manually setting the value of Header#raw to _raw_.
    def add(key, value, raw = nil)
      new_header = Redhead::Header.new(key, raw || to_raw[key], value)
      new_header.to_raw = to_raw
      self << new_header
      new_header
    end
    
    # Removes any headers with key names matching _key_ from the set.
    def delete(key)
      header = self[key]
      @headers.reject! { |header| header.key == key } ? header : nil
    end
    
    # Calls #to_s on each header in the set, joining the result with newlines.
    # 
    # If _hash_ has a key matching a header in the set, passes the value for that key in the hash
    # to Header#to_s. If _hash_ has no key for the header being iterated over, passes the given
    # block to Header#to_s instead.
    def to_s(hash = {}, &block)
      return @headers.map { |header| header.to_s }.join("\n") if hash.empty? && !block_given?
      
      @headers.map do |header|
        if hash.has_key?(header.key)
          header.to_s(hash[header.key])
        else
          header.to_s(&block)
        end
      end.join("\n")
    end
    
    # If a block is given, passes the block to Header#to_s! otherwise passes #to_raw instead. Joins
    # the result with newlines.
    def to_s!(&block)
      blk = block || to_raw
      @headers.map { |header| header.to_s!(&blk) }.join("\n")
    end
    
    # Returns true if Header#reversible? is true for each header in the set, otherwise false.
    def reversible?
      all? { |header| header.reversible? }
    end
    
    # Returns the Proc to be used to convert key names to raw header names. Defaults to Redhead.to_raw.
    def to_raw
      @to_raw || Redhead.to_raw
    end
    
    # Sets HeaderSet#to_raw to _new_to_raw_. Sets Header#to_raw for each header in the set to _new_to_raw_.
    def to_raw=(new_to_raw)
      @to_raw = new_to_raw
      each { |header| header.to_raw = new_to_raw }
    end
    
    # Returns the Proc to be used to convert raw header names to key names. Defaults to Redhead.to_key.
    def to_key
      @to_key || Redhead.to_key
    end
    
    # Sets HeaderSet#to_raw to _new_to_raw_. Sets Header#to_raw for each header in the set to _new_to_raw_.
    def to_key=(new_to_key)
      @to_key = new_to_key
      each { |header| header.to_key = new_to_key }
    end
    
    def inspect
      "{ #{@headers.map { |header| header.inspect }.join(", ")} }"
    end
    
    # Returns true if, for each header in the set, there is a header in _other_ for which header#==(other_header)
    # is true. Otherwise, returns false.
    def ==(other)
      @headers.all? do |header|
        other.find do |other_header|
          header == other_header
        end
      end
    end
  end
end
