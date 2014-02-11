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

      context "with \\r\\n separators" do
        subject { Redhead::String["foo: 1\r\nbar: 2\r\n\r\nbody"] }

        it "parses the headers in a retrievable way" do
          subject.headers[:foo].value.should == "1"
          subject.headers[:bar].value.should == "2"
        end
      end

      it "can handle strings with no headers" do
        expect { Redhead::String[""] }.to_not raise_error
        expect { Redhead::String["some content\n\nwith no headers"] }.to_not raise_error
      end

      it "can handle headers that have the header name-value separator in the value" do
        test_cases = ["foo: bar:baz", "foo: bar:baz\n", "foo: bar:baz\n\ncontent"]

        test_cases.each do |t|
          s = Redhead::String[t]
          s.headers.size.should == 1
          h = s.headers[:foo]
          h.should_not be_nil
          h.value.should == "bar:baz"
        end
      end

      it "handles header-only inputs" do
        Redhead::String["foo: bar"].to_s.should eq("")
        Redhead::String["foo: bar\n"].to_s.should eq("")
      end
    end

    describe ".has_headers?" do
      it "is true if the string has valid headers" do
        tests = {
          "foo: bar\n\ncontent" => true,
          "foo: bar" => true,
          "" => false,
          "some content\n\nhere" => false,
          "foo: bar:baz" => true,
          "foo: bar:baz\n" => true,
          "foo: bar:baz\n\ncontent" => true
        }

        tests.each do |input, value|
          Redhead::String.has_headers?(input).should == value
        end
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

    it "works for an empty string, too" do
      s = Redhead::String[""]
      s.headers.size.should == 0
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
