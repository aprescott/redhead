require "test_helper"

describe Redhead::String do
  before(:each) do
    @string_content = "Lorem ipsum dolor sit amet."
    @string = "A-Header-Value: value\n\n#{@string_content}"
    @rh_string = Redhead::String[@string]
    @copy_rh_string = Redhead::String[@string.clone]
  end
    
  context "as a class" do
    describe "self.[]" do
      it "is equal (==) in result to using .new" do
        Redhead::String[@string].should == Redhead::String.new(@string)
      end
    end
  end
  
  context "before any modifications:" do
    describe "#to_s" do
      it "returns a proper String instance" do
        @rh_string.to_s.class.should == String
      end
      
      it "is the contents of the header-less string" do
        @rh_string.to_s.should == @string_content
      end
      
      it "is not in fact the same object as its contained string" do
        @rh_string.to_s.equal?(@string_content).should be_false
      end
    end
  end
  
  describe "#headers" do
    it "returns a Redhead::HeaderSet object" do
      @rh_string.headers.is_a?(Redhead::HeaderSet).should be_true
    end
  end
  
  it "provides regular String methods" do
    String.instance_methods(false).each do |m|
      @rh_string.respond_to?(m).should be_true
    end
  end
  
  it "modifies its containing string with bang-methods" do
    orig = @rh_string.to_s.dup
    @rh_string.reverse!
    @rh_string.to_s.should == orig.reverse
    @rh_string.reverse!
    
    orig = @rh_string.to_s.dup
    @rh_string.upcase!
    @rh_string.to_s.should == orig.upcase
  end
    
  describe "#==" do
    it "returns true if the two Redhead strings contain equal headersets (using HeaderSet#==) and the same string content (using String#==)" do
      @rh_string.should == @rh_string
      @copy_rh_string.should == @rh_string
      
      # change the copy
      @copy_rh_string.headers[:a_header_value] = "something"
      @other_rh_string = @copy_rh_string
      
      @rh_string.headers.should_not == @other_rh_string.headers
      @rh_string.string.should == @other_rh_string.string
      @rh_string.should_not == @other_rh_string
    end
  end
  
  describe %Q{#headers!(:a => { :raw => "random raw", :key => "random key" })} do
    it %Q{modifies the header for key :a by calling raw="random raw", and key="random_key"} do
      header = @rh_string.headers[:a_header_value]
      header.raw.should_not == "random raw"
      header.key.should_not == "random key"
      
      @rh_string.headers!(:a_header_value => { :raw => "random raw", :key => "random key" })
      header.raw.should == "random raw"
      header.key.should == "random key"
    end
    
    it "ignores keys with no matching header" do
      expect { @rh_string.headers!(:lorem_ipsum_dolor_sit_amettttt => {}) }.to_not raise_error
    end
    
    it "returns only the changed headers" do
      @rh_string.headers!(:lorem_ipsum_dolor_sit_amet => {}).empty?.should be_true
      @rh_string.headers!(:a_header_value => {}).empty?.should_not be_true
      @rh_string.headers!(:a_header_value => {}).to_a.length.should == 1
    end
  end
end
