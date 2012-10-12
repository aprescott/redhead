require "test_helper"

describe Redhead::HeaderSet do
  before(:each) do
    @headers = []
    ("a".."c").map { |e| @headers << Redhead::Header.new(e.to_sym, "header_#{e}", "value_#{e}") }
    @full_header_set_string = ("a".."c").map { |e| "header_#{e}: value_#{e}" }.join("\n")
    @header = @headers.first
    @first_header_key = :a
    @header_set = Redhead::HeaderSet.new(@headers)
    
    @simple_headers = Redhead::HeaderSet.parse("A-Header: one\nA-Header-Two: two")
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
    end
    
    it "takes an optional third argument which sets the value of the raw header" do
      @header_set.add(:foo, "bar", "BAZ!")
      @header_set[:foo].value.should == "bar"
      @header_set[:foo].key.should == :foo
      @header_set[:foo].raw.should == "BAZ!"
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
      
      it "follows the hash argument first, falling back to the given block" do
        @header_set.to_s(:a => "something raw") { "NOT RAW AT ALL" }.split("\n").first.should == "something raw: value_a"
      end
    end
  end
  
  describe "#to_s!" do
    context "without a block" do
      it "calls to_s! on each header in the set, joining the results with newlines" do
        @simple_headers.to_s!.should == @simple_headers.map { |header| header.to_s! }.join("\n")
      end
    end
    
    context "with a block" do
      it "calls to_s! on each header in the set, passing the given block, joining the results with newlines" do
        @header_set.to_s! { "Total foo bar" }.should == @headers.map { |header| "Total foo bar: #{header.value}" }.join("\n")
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
end
