require "spec_helper"

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
        expect(Redhead::String[@string]).to eq(Redhead::String.new(@string))
      end

      context "with \\r\\n separators" do
        subject { Redhead::String["foo: 1\r\nbar: 2\r\n\r\nbody"] }

        it "parses the headers in a retrievable way" do
          expect(subject.headers[:foo].value).to eq("1")
          expect(subject.headers[:bar].value).to eq("2")
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
          expect(s.headers.size).to eq(1)
          h = s.headers[:foo]
          expect(h).not_to be_nil
          expect(h.value).to eq("bar:baz")
        end
      end

      it "handles header-only inputs" do
        expect(Redhead::String["foo: bar"].to_s).to eq("")
        expect(Redhead::String["foo: bar\n"].to_s).to eq("")
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
          expect(Redhead::String.has_headers?(input)).to eq(value)
        end
      end
    end
  end

  describe "#inspect" do
    specify { expect(@rh_string.inspect).to eq('+"Lorem ipsum dolor sit amet."') }
  end

  context "before any modifications:" do
    describe "#to_s" do
      it "returns a proper String instance" do
        expect(@rh_string.to_s.class).to eq(String)
      end

      it "is the contents of the header-less string" do
        expect(@rh_string.to_s).to eq(@string_content)
      end

      it "is not in fact the same object as its contained string" do
        expect(@rh_string.to_s.equal?(@string_content)).to be_false
      end
    end
  end

  describe "#headers" do
    it "returns a Redhead::HeaderSet object" do
      expect(@rh_string.headers.is_a?(Redhead::HeaderSet)).to be_true
    end

    it "works for an empty string, too" do
      s = Redhead::String[""]
      expect(s.headers.size).to eq(0)
    end
  end

  it "provides regular String methods" do
    String.instance_methods(false).each do |m|
      expect(@rh_string.respond_to?(m)).to be_true
    end
  end

  it "modifies its containing string with bang-methods" do
    orig = @rh_string.to_s.dup
    @rh_string.reverse!
    expect(@rh_string.to_s).to eq(orig.reverse)
    @rh_string.reverse!

    orig = @rh_string.to_s.dup
    @rh_string.upcase!
    expect(@rh_string.to_s).to eq(orig.upcase)
  end

  describe "#==" do
    it "returns true if the two Redhead strings contain equal headersets (using HeaderSet#==) and the same string content (using String#==)" do
      expect(@rh_string).to eq(@rh_string)
      expect(@copy_rh_string).to eq(@rh_string)

      # change the copy
      @copy_rh_string.headers[:a_header_value] = "something"
      @other_rh_string = @copy_rh_string

      expect(@rh_string.headers).not_to eq(@other_rh_string.headers)
      expect(@rh_string.string).to eq(@other_rh_string.string)
      expect(@rh_string).not_to eq(@other_rh_string)
    end
  end

  describe %Q{#headers!(a: { raw: "random raw", key: "random key" })} do
    it %Q{modifies the header for key :a by calling raw="random raw", and key="random_key"} do
      header = @rh_string.headers[:a_header_value]
      expect(header.raw).not_to eq("random raw")
      expect(header.key).not_to eq("random key")

      @rh_string.headers!(a_header_value: { raw: "random raw", key: "random key" })
      expect(header.raw).to eq("random raw")
      expect(header.key).to eq("random key")
    end

    it "ignores keys with no matching header" do
      expect { @rh_string.headers!(lorem_ipsum_dolor_sit_amettttt: {}) }.to_not raise_error
    end

    it "returns only the changed headers" do
      expect(@rh_string.headers!(lorem_ipsum_dolor_sit_amet: {}).empty?).to be_true
      expect(@rh_string.headers!(a_header_value: {}).empty?).not_to be_true
      expect(@rh_string.headers!(a_header_value: {}).to_a.length).to eq(1)
    end
  end
end
