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
        l.split(HEADER_NAME_VALUE_SEPARATOR_PATTERN).length == 2
      end

      return true if has_headers_no_content

      # split based on the headers separator and see if
      # all lines before the separator look like headers.

      string =~ HEADERS_SEPARATOR_PATTERN
      head_content = $`

      return false unless $`
      
      head_content.lines.all? do |l|
        l.split(HEADER_NAME_VALUE_SEPARATOR_PATTERN).length == 2
      end
    end
    
    # Takes _string_, splits the headers from the content using HEADERS_SEPARATOR_PATTERN, then
    # creates the headers by calling HeaderSet.parse.
    def initialize(string)
      if self.class.has_headers?(string)
        string =~ HEADERS_SEPARATOR_PATTERN
        @string = $'
        super(@string)
        
        @headers = Redhead::HeaderSet.parse($`)
      else
        @string = string
        super(@string)
        @headers = Redhead::HeaderSet.new([])
      end
    end
    
    # Returns the main body content wrapped in the Redhead String object.
    def to_s
      __getobj__
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
  
  private
  
  def __getobj__
    string
  end
end
