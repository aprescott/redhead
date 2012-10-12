require "test_helper"

describe Redhead::Header do
  before(:each) do
    @header_name = :a_header_name
    @header_raw_name = "A-Header-Name"
    @header_value = "some value"
    @separator = Redhead::HEADER_NAME_VALUE_SEPARATOR_CHARACTER
    
    @full_header_string = "#{@header_raw_name}#{@separator} #{@header_value}"
    
    @header = Redhead::Header.new(:a_header_name, "A-Header-Name", "some value")
    @header_copy = Redhead::Header.new(:a_header_name, "A-Header-Name", "some value")
    
    @different_header_raw_name = "An original HEADER name"
    @header_different_name = Redhead::Header.new(:a_header_name, "An original HEADER name", "something here")
  end
  
  context "as a class" do
    it "responds to :parse" do
      Redhead::Header.respond_to?(:parse).should be_true
    end
    
    describe "self.parse" do
      it "parses a string and returns a header" do
        parsed_header = Redhead::Header.parse(@full_header_string)
        parsed_header.class.should == Redhead::Header
        parsed_header.should_not be_nil
        parsed_header.key.should == @header_name
        parsed_header.value.should == @header_value
        parsed_header.raw.should == @header_raw_name
      end
      
      it "ignores consecutive non-separating characters by default" do
        parsed_header = Redhead::Header.parse("one very    strange!!! header: anything")
        parsed_header.key.should == :one_very_strange_header
      end
      
      it "ignores whitespace around `:` by default" do
        spaces = []
        
        20.times do |n|
          spaces << [" "*rand(n), " "*rand(n)]
        end
        
        spaces.each do |before, after|
          Redhead::Header.parse("#{@header_raw_name}#{before}:#{after}#{@header_value}").key.should == @header_name
        end
      end
    end
  end
  
  describe "#key" do
    it "returns the symbolic header name" do
      @header.key.should == :a_header_name
    end
  end
  
  describe "#raw" do
    it "returns the raw header name stored at creation time" do
      @header.raw.should == @header_raw_name
    end
  end
    
  describe "#value" do
    it "returns the header value" do
      @header.value.should == @header_value
    end
  end
  
  describe "#value=" do
    it "sets a new header value" do
      @header.value = "new value"
      @header.value.should == "new value"
    end
  end
    
  describe "#to_s" do
    it "returns <raw><separator> <value>" do
      @header.to_s.should == @full_header_string
    end
        
    context "with a block" do
      it "uses the given block to convert #key to a raw header, and returns the raw string" do
        @header.to_s { "test" }.should == "test#{@separator} #{@header_value}"
      end
    end
    
    it "takes an optional argument which specifies the raw header to use, without side-effects" do
      @header.to_s("test").should_not == @full_header_string
      @header.to_s("test").should == "test#{@separator} #{@header_value}"
      @header.to_s.should == @full_header_string
      @header.to_s.should_not == "test#{@separator} #{@header_value}"
    end
    
    it "ignores the given block if there is an explicit raw header name" do
      @header.to_s("test") { "foo" }.should_not == "foo#{@separator} #{@header_value}"
      @header.to_s("test") { "foo" }.should == "test#{@separator} #{@header_value}"
    end
  end
  
  describe "#==(other)" do
    it "returns true if self.raw == other.raw && self.value == other.value, otherwise false" do
      @header_copy.value = "something else entirely"
      @header.should_not == @header_copy
      
      # same raw name, same value
      Redhead::Header.new(:a_header_name, "A-Header-Name", "a").should == Redhead::Header.new(:a_header_name, "A-Header-Name", "a")
      
      # same raw name, different value
      Redhead::Header.new(:a_header_name, "A-Header-Name", "a").should_not == Redhead::Header.new(:a_header_name, "A-Header-Name", "aaaaaaa")
      
      # different raw name, same value
      Redhead::Header.new(:a_header_name, "A-Header-Name", "a").should_not == Redhead::Header.new(:a_header_name, "A-Header-Nameeeeeeee", "a")
    end
  end
  
  describe "#to_s!" do
    it "returns <computed_raw_header><separator> <value>" do
      @header.to_s!.should == "#{@header_raw_name}#{@separator} #{@header_value}"
      @header_different_name.to_s!.should == "#{@header_raw_name}#{@separator} something here"
    end
    
    context "with a block argument" do
      it "uses the given block to compute the raw header name" do
        @header.to_s! { "testing" }.should == "testing: #{@header_value}"
        @header.to_s! { |x| x.to_s.upcase.reverse.gsub("_", "-") }.should == "#{@header_raw_name.to_s.upcase.reverse}: #{@header_value}"
      end
    end
    
    it "takes an optional argument specifying the raw header name to use, without side-effects" do
      @header.to_s!("test").should_not == @full_header_string
      @header.to_s!("test").should == "test#{@separator} #{@header_value}"
      @header.to_s!.should == @full_header_string
      @header.to_s!.should_not == "test#{@separator} #{@header_value}"
    end
    
    it "ignores the given block if there is an explicit raw header name" do
      @header.to_s("test") { "foo" }.should_not == "foo#{@separator} #{@header_value}"
      @header.to_s("test") { "foo" }.should == "test#{@separator} #{@header_value}"
    end
  end
end
