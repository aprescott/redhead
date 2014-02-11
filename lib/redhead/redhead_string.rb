require "delegate"

module Redhead
  class String < SimpleDelegator
    attr_reader :headers, :string
    
    class << self
      alias_method :[], :new
    end

    # Checks if the input string has header lines at the start of its content,
    # and returns true or false depending on the value.
    def self.has_headers?(string)
      return false if string.strip.empty?

      # check if the string itself is entirely headers
      has_headers_no_content = string.strip.lines.all? do |l|
        l =~ HEADER_NAME_VALUE_SEPARATOR_PATTERN
      end

      return true if has_headers_no_content

      # split based on the headers separator and see if
      # all lines before the separator look like headers.

      string =~ HEADERS_SEPARATOR_PATTERN
      head_content = $`

      return false unless $`
      
      head_content.lines.all? do |l|
        l =~ HEADER_NAME_VALUE_SEPARATOR_PATTERN
      end
    end
    
    # Takes _string_, splits the headers from the content using HEADERS_SEPARATOR_PATTERN, then
    # creates the headers by calling HeaderSet.parse.
    def initialize(string)
      if self.class.has_headers?(string)
        # if there is a separator between header content and body content
        if string =~ HEADERS_SEPARATOR_PATTERN
          @string = $'
          header_content = $`
          super(@string)

          @headers = Redhead::HeaderSet.parse(header_content)
        else
          @string = ""
          super(@string)

          # we're dealing with only headers, so pass in the entire original string.
          # this lets us deal with inputs like new("foo: bar")
          @headers = Redhead::HeaderSet.parse(string)
        end
      else
        @string = string
        super(@string)
        @headers = Redhead::HeaderSet.new([])
      end
    end
    
    # Returns the main body content wrapped in the Redhead String object.
    def to_s
      @string
    end
    
    def inspect
      "+#{string.inspect}"
    end
    
    # Returns true if self.headers == other.headers and self.string == other.string.
    def ==(other)
      headers == other.headers && string == other.string
    end
    
    # Modifies the headers in the set, using the given _hash_, which has the form
    # 
    #     { :some_header => { :raw => a, :key => b }, :another_header => ..., ... }
    # 
    # Change the header with key :some_header such that its new raw name is _a_ and its new key name
    # is _b_. Returns a HeaderSet object containing the changed Header objects.
    def headers!(hash)
      changing = headers.select { |header| hash.has_key?(header.key) }
      
      # modifies its elements!
      changing.each do |header|
        new_values = hash[header.key]
        header.raw = new_values[:raw] if new_values[:raw]
        header.key = new_values[:key] if new_values[:key]
      end
      
      Redhead::HeaderSet.new(changing)
    end
  end
end
