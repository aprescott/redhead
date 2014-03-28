require "spec_helper"

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
        expect(Redhead::HeaderSet.parse(@full_header_set_string)).to eq(parsed_header_set)
      end
    end
  end

  it "is Enumerable and responds to #each" do
    expect(@header_set.is_a?(Enumerable)).to be_true
    expect(@header_set.respond_to?(:each)).to be_true
  end

  describe "#[]" do
    context "for a key with a corresponding header" do
      it "takes a symbolic header name key and returns a header" do
        expect(@header_set[:a].is_a?(Redhead::Header)).to be_true
      end
    end

    context "for a key with no corresponding header" do
      it "returns nil" do
        expect(@header_set[:something_non_existent]).to be_nil
      end
    end
  end

  describe "#[]=" do
    context "for a key with a corresponding header" do
      it "sets a new header value" do
        new_value = "new value"
        expect(@header_set[@first_header_key]).not_to be_nil
        @header_set[@first_header_key] = new_value
        expect(@header_set[@first_header_key].value).to eq(new_value)
      end
    end

    context "for a key with no corresponding header" do
      it "creates a new header with this value" do
        new_value = "some brand new value"
        @header_set[:brand_new_key] = new_value
        expect(@header_set[:brand_new_key]).not_to be_nil
        expect(@header_set[:brand_new_key].value).to eq(new_value)
      end
    end
  end

  describe "#add" do
    context "being equivalent to #[]=" do
      def new_header(header_string)
        expect(@header_set[:brand_new_key]).to be_nil
        @header_set.add(:brand_new_key, "some value")
        expect(@header_set[:brand_new_key]).not_to be_nil
      end

      it "parses the given header string, adds the new header to self and returns that header" do
        new_header(@header_set)
      end

      it "creates a new header with the given value" do
        new_header(@header_set)
        expect(@header_set[:brand_new_key].value).to eq("some value")
      end

      it "returns a Redhead::Header object" do
        expect(@header_set.add(:brand_new_key, "some value").class).to eq(Redhead::Header)
      end
    end

    it "takes an optional third argument which sets the value of the raw header" do
      @header_set.add(:foo, "bar", "BAZ!")
      expect(@header_set[:foo].value).to eq("bar")
      expect(@header_set[:foo].key).to eq(:foo)
      expect(@header_set[:foo].raw).to eq("BAZ!")
    end
  end

  describe "#delete" do
    it "removes a header from the set" do
      expect(@header_set[:brand_new_key]).to be_nil
      @header_set[:brand_new_key] = "something random"
      expect(@header_set[:brand_new_key]).not_to be_nil
      new_header = @header_set[:brand_new_key]
      @header_set.delete(:brand_new_key)
      expect(@header_set[:brand_new_key]).to be_nil
    end

    it "returns the deleted header" do
      @header_set[:brand_new_key] = "test"
      h = @header_set[:brand_new_key]
      expect(@header_set.delete(:brand_new_key)).to eq(h)
    end

    it "returns nil if there is no header corresponding to the key" do
      expect(@header_set[:brand_new_key]).to be_nil
      expect(@header_set.delete(:brand_new_key)).to be_nil
    end
  end

  # to_hash is an alias for to_h

  [:to_h, :to_hash].each do |meth|
    describe "##{meth}" do
      it "returns a Hash instance containing symbol keys and header values" do
        expect(@header_set.public_send(meth)).to eq(Hash[@headers.map { |header| [header.key, header.value] }])
      end

      it "contains only keys in the original header" do
        expect(@header_set.public_send(meth).keys).to eq(@headers.map { |header| header.key })
      end

      it "contains correct corresponding values for each key" do
        h = @header_set.public_send(meth)
        expect(h.keys.size).to eq(@header_set.size)

        h.each do |key, value|
          expect(@header_set[key].value).to eq(value)
        end
      end
    end
  end

  describe "#size" do
    it "is the number of headers in the set" do
      expect(@header_set.size).to eq(@headers.size)
    end
  end

  describe "#to_s" do
    it "equals the individual header to_s results, joined with newlines" do
      expect(@header_set.to_s).to eq(@headers.map { |header| header.to_s }.join("\n"))
    end

    context %Q{with a hash argument a: "something raw"} do
      def modified_full_header_set_string
        str = "something raw: value_a\n"
        str += @headers[1..-1].map { |e| "header_#{e.key}: value_#{e.key}" }.join("\n")
        str
      end

      it %Q{sets the header with key :a to have #raw == "one" and #value == 1} do
        str = modified_full_header_set_string

        expect(@header_set.to_s(a: "something raw")).to eq(str)
        expect(@header_set[:a].raw).not_to eq("something raw")
        expect(@header_set[:a].raw).to eq("header_a")
      end

      it "does not leave a side-effect" do
        str = modified_full_header_set_string

        expect(@header_set.to_s(a: "something raw")).to eq(str)
        expect(@header_set[:a].raw).not_to eq("something raw")
        expect(@header_set[:a].raw).to eq("header_a")
      end
    end

    context "with a block argument" do
      def modified_full_header_set_string
        @headers.map { |e| "#{yield e.key}: value_#{e.key}" }.join("\n")
      end

      it "uses the given block to convert #key to a raw header, for each header in the set" do
        expect(@header_set.to_s { "testing" + "testing" }).to eq(modified_full_header_set_string { "testing" + "testing" })

        new_to_raw = proc { |x| x.to_s.upcase.reverse }

        expect(@header_set.to_s(&new_to_raw)).to eq(modified_full_header_set_string(&new_to_raw))
      end

      it "follows the hash argument first, falling back to the given block" do
        expect(@header_set.to_s(a: "something raw") { "NOT RAW AT ALL" }.split("\n").first).to eq("something raw: value_a")
      end
    end
  end

  describe "#to_s!" do
    context "without a block" do
      it "calls to_s! on each header in the set, joining the results with newlines" do
        expect(@simple_headers.to_s!).to eq(@simple_headers.map { |header| header.to_s! }.join("\n"))
      end
    end

    context "with a block" do
      it "calls to_s! on each header in the set, passing the given block, joining the results with newlines" do
        expect(@header_set.to_s! { "Total foo bar" }).to eq(@headers.map { |header| "Total foo bar: #{header.value}" }.join("\n"))
      end
    end
  end

  describe "#==(other_header)" do
    it "is sane." do
      expect(@header_set).to eq(@header_set)

      expect(Redhead::HeaderSet.parse("Test: test")).to eq(Redhead::HeaderSet.parse("Test: test"))
    end

    it "returns true if, for every header in self, there is a corresponding header in other_header equal to it, using Header#==" do
      one, two = @header_set.partition { |header| header.key.to_s < @header_set.to_a[1].key.to_s }.map { |part| Redhead::HeaderSet.new(part) }

      expect(one.all? { |a| two.find { |b| a == b } }).to be_false
      # sanity check with any?
      expect(one.any? { |a| two.find { |b| a == b } }).to be_false

      one << two.first # create an overlap

      expect(one.all? { |a| two.find { |b| a == b } }).to be_false
      # sanity check with any?
      expect(one.any? { |a| two.find { |b| a == b } }).to be_true
    end
  end
end
