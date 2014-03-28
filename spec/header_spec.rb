require "spec_helper"

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
      expect(Redhead::Header.respond_to?(:parse)).to be_true
    end

    describe "self.parse" do
      it "parses a string and returns a header" do
        parsed_header = Redhead::Header.parse(@full_header_string)
        expect(parsed_header.class).to eq(Redhead::Header)
        expect(parsed_header).not_to be_nil
        expect(parsed_header.key).to eq(@header_name)
        expect(parsed_header.value).to eq(@header_value)
        expect(parsed_header.raw).to eq(@header_raw_name)
      end

      it "ignores consecutive non-separating characters by default" do
        parsed_header = Redhead::Header.parse("one very    strange!!! header: anything")
        expect(parsed_header.key).to eq(:one_very_strange_header)
      end

      it "ignores whitespace around `:` by default" do
        spaces = []

        20.times do |n|
          spaces << [" "*rand(n), " "*rand(n)]
        end

        spaces.each do |before, after|
          expect(Redhead::Header.parse("#{@header_raw_name}#{before}:#{after}#{@header_value}").key).to eq(@header_name)
        end
      end

      it "handles values with a separator" do
        header = Redhead::Header.parse("created: 20:30")
        expect(header.key).to eq(:created)
        expect(header.value).to eq("20:30")
      end
    end
  end

  describe "#inspect" do
    specify { expect(@header.inspect).to eq('{ :a_header_name => "some value" }') }
  end

  describe "#key" do
    it "returns the symbolic header name" do
      expect(@header.key).to eq(:a_header_name)
    end
  end

  describe "#raw" do
    it "returns the raw header name stored at creation time" do
      expect(@header.raw).to eq(@header_raw_name)
    end
  end

  describe "#value" do
    it "returns the header value" do
      expect(@header.value).to eq(@header_value)
    end
  end

  describe "#value=" do
    it "sets a new header value" do
      @header.value = "new value"
      expect(@header.value).to eq("new value")
    end
  end

  describe "#to_s" do
    it "returns <raw><separator> <value>" do
      expect(@header.to_s).to eq(@full_header_string)
    end

    context "with a block" do
      it "uses the given block to convert #key to a raw header, and returns the raw string" do
        expect(@header.to_s { "test" }).to eq("test#{@separator} #{@header_value}")
      end
    end

    it "takes an optional argument which specifies the raw header to use, without side-effects" do
      expect(@header.to_s("test")).not_to eq(@full_header_string)
      expect(@header.to_s("test")).to eq("test#{@separator} #{@header_value}")
      expect(@header.to_s).to eq(@full_header_string)
      expect(@header.to_s).not_to eq("test#{@separator} #{@header_value}")
    end

    it "ignores the given block if there is an explicit raw header name" do
      expect(@header.to_s("test") { "foo" }).not_to eq("foo#{@separator} #{@header_value}")
      expect(@header.to_s("test") { "foo" }).to eq("test#{@separator} #{@header_value}")
    end
  end

  describe "#==(other)" do
    it "returns true if self.raw == other.raw && self.value == other.value, otherwise false" do
      @header_copy.value = "something else entirely"
      expect(@header).not_to eq(@header_copy)

      # same raw name, same value
      expect(Redhead::Header.new(:a_header_name, "A-Header-Name", "a")).to eq(Redhead::Header.new(:a_header_name, "A-Header-Name", "a"))

      # same raw name, different value
      expect(Redhead::Header.new(:a_header_name, "A-Header-Name", "a")).not_to eq(Redhead::Header.new(:a_header_name, "A-Header-Name", "aaaaaaa"))

      # different raw name, same value
      expect(Redhead::Header.new(:a_header_name, "A-Header-Name", "a")).not_to eq(Redhead::Header.new(:a_header_name, "A-Header-Nameeeeeeee", "a"))
    end
  end

  describe "#to_s!" do
    it "returns <computed_raw_header><separator> <value>" do
      expect(@header.to_s!).to eq("#{@header_raw_name}#{@separator} #{@header_value}")
      expect(@header_different_name.to_s!).to eq("#{@header_raw_name}#{@separator} something here")
    end

    context "with a block argument" do
      it "uses the given block to compute the raw header name" do
        expect(@header.to_s! { "testing" }).to eq("testing: #{@header_value}")
        expect(@header.to_s! { |x| x.to_s.upcase.reverse.gsub("_", "-") }).to eq("#{@header_raw_name.to_s.upcase.reverse}: #{@header_value}")
      end
    end

    it "takes an optional argument specifying the raw header name to use, without side-effects" do
      expect(@header.to_s!("test")).not_to eq(@full_header_string)
      expect(@header.to_s!("test")).to eq("test#{@separator} #{@header_value}")
      expect(@header.to_s!).to eq(@full_header_string)
      expect(@header.to_s!).not_to eq("test#{@separator} #{@header_value}")
    end

    it "ignores the given block if there is an explicit raw header name" do
      expect(@header.to_s("test") { "foo" }).not_to eq("foo#{@separator} #{@header_value}")
      expect(@header.to_s("test") { "foo" }).to eq("test#{@separator} #{@header_value}")
    end
  end
end
