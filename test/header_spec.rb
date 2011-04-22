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
    
    @default_to_raw = Redhead.to_raw
    @default_to_key = Redhead.to_key
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
      
      context "with a given block" do
        it "uses the given block as to_key" do
          Redhead::Header.parse(@full_header_string) { :foo }.key.should == :foo
        end
        
        # do not set to_key to the given block so that using parse with a block does not prevent any dynamic
        # calls up the chain to work out what to_raw should be for each object. i.e., Header#to_key should default
        # to Redhead.to_key, but since each header doesn't know which headerset it's in, HeaderSet needs to pass down
        # a block to each Header object. if the Header object set the block as to_key, there'd be problems.
        # 
        # Similarly, Redhead::String.parse(..., &blk) should not set Header#to_key because then there'd never be any
        # calls up the hierarchy, since an individual Header's @to_key would exist already.
        it "sets to_key to the given block" do
          # note: Proc#== bug!
          to_key = proc { :foo }
          Redhead::Header.parse(@full_header_string, &to_key).to_key.should_not == to_key
        end
      end
    end
  end
  
  describe "#key" do
    it "returns the symbolic header name" do
      @header.key.should == :a_header_name
    end
  end
  
  describe "#key!" do
    it "uses #to_key to convert #raw to a header key" do
      @header.to_key = proc { "test" }
      @header.key!.should == "test"
      
      @header.to_key = proc { |x| x.upcase.reverse.gsub("-", "_").to_sym }
      @header.key!.should == @header_raw_name.upcase.reverse.gsub("-", "_").to_sym
    end
    
    it "does not change #key after being called" do
      @header.to_key = proc { "test" }
      @header.key.should == @header_name
      @header.key!.should == "test"
      @header.key.should_not == "test"
      @header.key.should == @header_name
    end
  end
  
  describe "#raw" do
    it "returns the raw header name stored at creation time" do
      @header.raw.should == @header_raw_name
      @header.to_raw = proc { "" }
      @header.raw!.should == ""
      @header.raw.should == @header_raw_name
    end
  end
  
  describe "#raw!" do
    it "uses #to_raw to convert #key to a raw header, ignoring the value of #raw" do
      @header.to_raw = proc { "test" }
      @header.raw!.should == "test"
      
      @header.to_raw = proc { |x| x.to_s.upcase.reverse }
      @header.raw!.should == @header_name.to_s.upcase.reverse
    end
    
    it "does not change #raw after being called" do
      @header.to_raw = proc { "test" }
      @header.raw.should == @header_raw_name
      @header.raw!.should == "test"
      @header.raw.should_not == "test"
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
      
      it "does not set a new value for #to_raw" do
        @header.to_s { "test" }
        @header.to_s.should_not == "test#{@separator} #{@header_value}"
        @header.to_s.should == @full_header_string
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
  
  describe "#reversible?" do
    it "returns true for the defaults" do
      @header.reversible?.should be_true
    end
    
    it "returns true if self.to_raw[self.key!] == self.raw, i.e., if we can't recover the current raw header name via to_key(to_raw(current_raw_header_name))" do
      @header.to_raw[@header.key!].should == @header_raw_name
      @header.reversible?.should be_true # by default
      
      @header.to_raw = proc { |x| "1#{x}" }
      @header.to_key = proc { |x| "2#{x}" }
      @header.to_raw[@header.key!].should_not == @header_raw_name
      @header.reversible?.should be_false # :key does not equal 2Key1Key
      
      @header.to_raw = proc { |x| x.to_s.reverse }
      @header.to_key = proc { |x| x.reverse.to_sym }
      @header.to_raw[@header.key!].should == @header_raw_name
      @header.reversible?.should be_true
    end
  end
  
  describe "#to_raw" do
    it "returns Redhead.to_raw by default" do
      # note: Proc#== bug!
      @header.to_raw.should == @default_to_raw
    end
  end
    
  describe "#to_key" do
    it "returns Redhead.to_key by default" do
      # note: Proc#== bug!
      @header.to_key.should == @default_to_key
    end
  end
  
  describe "#to_raw=(blk)" do
    it "sets to_raw to blk" do
      new_block = proc { }
      @header.to_raw.should_not == new_block
      @header.to_raw = new_block
      @header.to_raw.should == new_block
    end
  end
  
  describe "#to_key=(blk)" do
    it "sets to_key to blk" do
      new_block = proc { "" + "" }
      @header.to_key.should_not == new_block
      @header.to_key = new_block
      @header.to_key.should == new_block
    end
  end
  
  describe "#to_s!" do
    # TODO: this test doesn't do what it should. know what @header.raw! is going to be and use it in this test
    # instead of relying on @header.raw! in this test itself. better go through all tests and double-check this.
    it "returns <raw!><separator> <value>" do
      @header.to_s!.should == "#{@header.raw!}#{@separator} #{@header_value}"
    end
    
    context "with a block argument" do
      it "uses the given block as though it were #to_raw" do
        @header.to_s! { "testing" }.should == "testing: #{@header_value}"
        @header.to_s! { |x| x.to_s.upcase.reverse.gsub("_", "-") }.should == "#{@header_raw_name.to_s.upcase.reverse}: #{@header_value}"
      end
      
      it "does not leave to_raw as the given block" do
        @header.to_s! { "testing" }
        @header.to_raw.should_not == proc { "testing" }
        @header.to_raw[:random].should_not == "testing"
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
