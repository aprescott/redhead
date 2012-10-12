module Redhead
  class HeaderSet
    include Enumerable
    
    # Sets the headers of the set to _headers_. _headers_ is assumed to be ordered.
    def initialize(headers)
      @headers = headers
    end
    
    # Parses lines of header strings with Header.parse. Returns a new HeaderSet object
    # for the parsed headers.
    def self.parse(header_string)
      headers = []
      header_string.split("\n").each do |str|
        headers << Redhead::Header.parse(str)
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
    # If there is no header matching _key_, create a new header with the given key and value.
    def []=(key, value)
      h = self[key]      
      if h
        h.value = value
      else
        new_header = Redhead::Header.new(key, TO_RAW[key], value)
        self << new_header
      end
    end
    
    # Adds _header_ to the set of headers.
    def <<(header)
      @headers << header
    end
    
    # Similar to #[]= but allows manually setting the value of Header#raw to _raw_.
    def add(key, value, raw = nil)
      new_header = Redhead::Header.new(key, raw || TO_RAW[key], value)
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
    
    # If a block is given, passes the block to Header#to_s! Joins
    # the result with newlines.
    def to_s!(&block)
      blk = block || TO_RAW
      @headers.map { |header| header.to_s!(&blk) }.join("\n")
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
