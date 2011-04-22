require "test_helper"

describe Redhead::HeaderSet do
  before(:each) do
    @headers = []
    ("a".."c").map { |e| @headers << Redhead::Header.new(e.to_sym, "header_#{e}", "value_#{e}") }
    @full_header_set_string = ("a".."c").map { |e| "header_#{e}: value_#{e}" }.join("\n")
    @header = @headers.first
    @first_header_key = :a
    @header_set = Redhead::HeaderSet.new(@headers)
    @default_to_raw = Redhead.to_raw
    @default_to_key = Redhead.to_key
    
    @reversible_headers = Redhead::HeaderSet.parse("A-Header: one\nA-Header-Two: two")
    @irreversible_headers = Redhead::HeaderSet.parse("a_header: one\na_header_two: two")
  end
    
  context "as a class" do
    describe ".parse" do
      it "calls Header.parse on each header line, to create a set of headers" do
        string = @full_header_set_string + Redhead::HEADERS_SEPARATOR + "some content goes here"
        header_lines = @full_header_set_string.split("\n")
        parsed_header_set = Redhead::HeaderSet.new(header_lines.map { |header_line| Redhead::Header.parse(header_line) })
        Redhead::HeaderSet.parse(@full_header_set_string).should == parsed_header_set
      end
    end
    
    context "with a block" do
      it "uses the given block as to_key" do
        Redhead::HeaderSet.parse(@full_header_set_string) { :foo }.each { |h| h.key.should == :foo }
      end
      
      it "does not set to_key on each parsed header object in the set" do
        # note: Proc#== bug!
        to_key =  proc { :foo }
        Redhead::HeaderSet.parse(@full_header_set_string, &to_key).each { |header| header.to_key.should_not == to_key }
      end
    end
  end
  
  it "is Enumerable and responds to #each" do
    @header_set.is_a?(Enumerable).should be_true
    @header_set.respond_to?(:each).should be_true
  end
  
  describe "#[]" do
    context "for a key with a corresponding header" do
      it "takes a symbolic header name key and returns a header" do
        @header_set[:a].is_a?(Redhead::Header).should be_true
      end
    end
    
    context "for a key with no corresponding header" do
      it "returns nil" do
        @header_set[:something_non_existent].should be_nil
      end
    end
  end
  
  describe "#[]=" do
    context "for a key with a corresponding header" do
      it "sets a new header value" do
        new_value = "new value"
        @header_set[@first_header_key].should_not be_nil
        @header_set[@first_header_key] = new_value
        @header_set[@first_header_key].value.should == new_value
      end
    end
    
    context "for a key with no corresponding header" do
      it "creates a new header with this value" do
        new_value = "some brand new value"
        @header_set[:brand_new_key] = new_value
        @header_set[:brand_new_key].should_not be_nil
        @header_set[:brand_new_key].value.should == new_value
      end
      
      it "calls #to_raw to create the value of #raw" do
        @header_set.to_raw = proc { "WHOA!" }
        @header_set[:brand_new_key] = "some value"
        @header_set[:brand_new_key].raw.should == "WHOA!"
      end
      
      it "sets new_header#to_raw to header_set#to_raw" do
        @header_set.to_raw = proc { "Whoa!" }
        @header_set[:brand_new_key] = "some value"
        @header_set[:brand_new_key].to_raw.should == @header_set.to_raw
      end
    end
  end
  
  describe "#add" do
    context "being equivalent to #[]=" do
      def new_header(header_string)
        @header_set[:brand_new_key].should be_nil
        @header_set.add(:brand_new_key, "some value")
        @header_set[:brand_new_key].should_not be_nil
      end
    
      it "parses the given header string, adds the new header to self and returns that header" do
        new_header(@header_set)
      end
    
      it "creates a new header with the given value" do
        new_header(@header_set)
        @header_set[:brand_new_key].value.should == "some value"
      end
      
      it "returns a Redhead::Header object" do
        @header_set.add(:brand_new_key, "some value").class.should == Redhead::Header
      end
      
      it "calls #to_raw to create the value of #raw" do
        @header_set.add(:brand_new_key, "some value")
        @header_set[:brand_new_key].raw.should == "Brand-New-Key"
        
        @header_set.to_raw = proc { "Nothing really" }
        @header_set.add(:something_or_other, "something or other")
        @header_set[:something_or_other].raw.should == "Nothing really"
      end
      
      it "sets new_header#to_raw to header_set#to_raw" do
        @header_set.to_raw = proc { "Whoa!" }
        @header_set.add(:brand_new_key, "some value")
        @header_set[:brand_new_key].to_raw.should == @header_set.to_raw
      end
    end
    
    it "takes an optional third argument which sets the value of the raw header" do
      @header_set.add(:foo, "bar", "BAZ!")
      @header_set[:foo].value.should == "bar"
      @header_set[:foo].key.should == :foo
      @header_set[:foo].raw.should == "BAZ!"
      @header_set[:foo].raw!.should == "Foo"
    end
  end
  
  describe "#delete" do
    it "removes a header from the set" do
      @header_set[:brand_new_key].should be_nil
      @header_set[:brand_new_key] = "something random"
      @header_set[:brand_new_key].should_not be_nil
      new_header = @header_set[:brand_new_key]
      @header_set.delete(:brand_new_key)
      @header_set[:brand_new_key].should be_nil
    end
    
    it "returns the deleted header" do
      @header_set[:brand_new_key] = "test"
      h = @header_set[:brand_new_key]
      @header_set.delete(:brand_new_key).should == h
    end
    
    it "returns nil if there is no header corresponding to the key" do
      @header_set[:brand_new_key].should be_nil
      @header_set.delete(:brand_new_key).should be_nil
    end
  end
  
  describe "#to_s" do
    it "equals the individual header to_s results, joined with newlines" do
      @header_set.to_s.should == @headers.map { |header| header.to_s }.join("\n")
    end
    
    context %Q{with a hash argument :a => "something raw"} do
      def modified_full_header_set_string
        str = "something raw: value_a\n"
        str += @headers[1..-1].map { |e| "header_#{e.key}: value_#{e.key}" }.join("\n")
        str
      end
      
      it %Q{sets the header with key :a to have #raw == "one" and #value == 1} do
        str = modified_full_header_set_string
        
        @header_set.to_s(:a => "something raw").should == str
        @header_set[:a].raw.should_not == "something raw"
        @header_set[:a].raw.should == "header_a"
      end
            
      it "does not leave a side-effect" do
        str = modified_full_header_set_string
        
        @header_set.to_s(:a => "something raw").should == str
        @header_set[:a].raw.should_not == "something raw"
        @header_set[:a].raw.should == "header_a"
      end
    end
    
    context "with a block argument" do
      def modified_full_header_set_string
        @headers.map { |e| "#{yield e.key}: value_#{e.key}" }.join("\n")
      end
      
      it "uses the given block to convert #key to a raw header, for each header in the set" do
        @header_set.to_s { "testing" + "testing" }.should == modified_full_header_set_string { "testing" + "testing" }
        
        new_to_raw = proc { |x| x.to_s.upcase.reverse }
        
        @header_set.to_s(&new_to_raw).should == modified_full_header_set_string(&new_to_raw)
      end
      
      it "does not leave the given block as #to_raw" do
        @header_set.to_s { "test" + "test" }
        @header_set.to_raw.should_not == proc { "test" + "test" }
      end
      
      it "follows the hash argument first, falling back to the given block" do
        @header_set.to_s(:a => "something raw") { "NOT RAW AT ALL" }.split("\n").first.should == "something raw: value_a"
      end
    end
  end
  
  describe "#to_s!" do
    context "without a block" do
      it "calls to_s! on each header in the set, passing #to_raw as a block joining the results with newlines" do
        @header_set.to_raw = proc { "Total foo bar" }
        @header_set.to_s!.should == @headers.map { |header| "Total foo bar: #{header.value}" }.join("\n")
      end
    end
    
    context "with a block" do
      it "calls to_s! on each header in the set, passing the given block, joining the results with newlines" do
        @header_set.to_s! { "Total foo bar" }.should == @headers.map { |header| "Total foo bar: #{header.value}" }.join("\n")
      end
      
      it "does not leave the given block as #to_raw on existing headers" do
        temp_to_raw = proc { "Total foo bar" }
        @header_set.to_s!(&temp_to_raw)
        @header_set.all? { |header| header.raw!.should_not == "Total foo bar" }
      end
      
      it "does not leave the given block as #to_raw on the header set" do
        temp_to_raw = proc { "Total foo bar" }
        @header_set.to_s!(&temp_to_raw)
        @header_set.to_raw.should_not == temp_to_raw
        @header_set[:temp_foo_foo] = "what"
        @header_set[:temp_foo_foo].raw!.should_not == "Total foo bar"
      end
    end
  end
  
  describe "#==(other_header)" do
    it "is sane." do
      @header_set.should == @header_set
      
      Redhead::HeaderSet.parse("Test: test").should == Redhead::HeaderSet.parse("Test: test")
    end
    
    it "returns true if, for every header in self, there is a corresponding header in other_header equal to it, using Header#==" do
      one, two = @header_set.partition { |header| header.key.to_s < @header_set.to_a[1].key.to_s }.map { |part| Redhead::HeaderSet.new(part) }
      
      one.all? { |a| two.find { |b| a == b } }.should be_false
      # sanity check with any?
      one.any? { |a| two.find { |b| a == b } }.should be_false
      
      one << two.first # create an overlap
      
      one.all? { |a| two.find { |b| a == b } }.should be_false
      # sanity check with any?
      one.any? { |a| two.find { |b| a == b } }.should be_true
    end
  end
  
  describe "#reversible?" do
    it "returns true if each header in the set is reversible, otherwise false" do
      @reversible_headers.reversible?.should == @reversible_headers.all? { |header| header.reversible? }
      @irreversible_headers.reversible?.should == @irreversible_headers.all? { |header| header.reversible? }
      
      @reversible_headers.reversible?.should be_true
      @irreversible_headers.reversible?.should be_false
      
      @reversible_headers.to_raw = proc { "" }
      @reversible_headers.reversible?.should_not be_true # contained headers get caught up in the change
      
      # example from the readme:
      
      string = "A-Header-Name: a header value\n\nContent."
      
      str = Redhead::String.new(string) do |name|
        name.gsub(/-/, "").upcase.to_sym
      end
      
      str.headers.reversible?.should be_false
      
      str = Redhead::String.new(string) do |name|
        name.split(/-/).map { |e| e.upcase }.join("zzz").to_sym
      end
      
      str.headers.reversible?.should be_false
      
      str.headers.to_raw = lambda do |name|
        name.to_s.split(/zzz/).map { |e| e.capitalize }.join("-")
      end
      
      str.headers.reversible?.should be_true
    end
  end
  
  describe "#to_raw" do
    it "defaults to Redhead.to_raw" do
      # note: Proc#== bug!
      @header_set.to_raw.should == @default_to_raw
    end
  end
  
  describe "#to_raw=" do
    it "sets a new block to be used as to_raw" do
      # note: Proc#== bug!
      new_to_raw = proc { "" + "" }
      @header_set.to_raw = new_to_raw
      @header_set.to_raw.should_not == @default_to_raw
      @header_set.to_raw.should == new_to_raw
    end
    
    it "sets to_raw, for each header in the set" do
      new_to_raw = proc { "" + "" }
      @header_set.to_raw = new_to_raw
      @header_set.each { |header| header.to_raw.should == new_to_raw }
    end
  end
  
  describe "#to_key" do
    it "defaults to Redhead.to_key" do
      # note: Proc#== bug!
      @header_set.to_key.should == @default_to_key
    end
  end
  
  describe "#to_key=" do
    it "sets a new block to be used as to_key" do
      # note: Proc#== bug!
      new_to_key = proc { "" + "" }
      @header_set.to_key = new_to_key
      @header_set.to_key.should_not == @default_to_key
      @header_set.to_key.should == new_to_key
    end
    
    it "sets to_key, for each header in the set" do
      new_to_key = proc { "" + "" }
      @header_set.to_key = new_to_key
      @header_set.each { |header| header.to_key.should == new_to_key }
    end
  end
end
