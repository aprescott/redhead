# What is it?

Redhead is for header metadata in strings, in the style of HTTP and email. It makes just a few assumptions about your header names and values, keeps them all as strings, and leaves the rest to you.

# How do I use this thing?

## Basics

A variable `post` referencing a simple string can be wrapped up in a `Redhead::String` object.

	>> puts post
	Title: Redhead is for headers!
	Tags: redhead, ruby, headers
	
	Since time immemorial, ...
	
	>> post = Redhead::String[post]
	=> +"Since time immemorial, ..."
	
	>> post.headers
	=> { { :title => "Redhead is for headers" }, { :tags => "redhead, ruby, headers" } }
	
	>> post
	=> +"Since time immemorial, ..."
	
	>> post.to_s
	=> "Since time immemorial, ..."

(Note that the `:tags` header has a string value, not an array!)

A Redhead::String is prefixed with `+` when inspecting it, so as to distinguish it from a proper `String` instance.

## Regular string functionality

A Redhead string has the functionality of a regular Ruby string.

	>> post.split(/,/).first.reverse
	=> "lairomemmi emit ecniS"
	
	>> post.split(/ /).first
	=> "Since"
	
	# Modifies the receiver!
	>> post.reverse!
	=> "... ,lairomemmi emit ecniS"
	
	>> post.to_s
	=> "..., lairomemmi emit ecniS"
	
	>> post.headers
	=> { { :title => "Redhead is for headers" }, { :tags => "redhead, ruby, headers" } }
	
	>> post.replace("Better content.")
	=> "Better content."
	
	>> post.to_s
	=> "Better content."
	
	>> post.headers
	=> { { :title => "Redhead is for headers" }, { :tags => "redhead, ruby, headers" } }

Note that `String` instance methods which are not receiver-modifying will return proper `String` instances, and so headers will be lost.

## Accessing

In addition, you get access to headers.

	>> post.headers[:title]
	=> { :title => "Redhead is for headers!" }
	
	>> post.headers[:tags].to_s
	=> "redhead, ruby, headers"
	
	>> post.headers.to_s
	=> "Title: Redhead is for headers!\nTags: redhead, ruby, headers"

## Changing values

Modifying a header value is easy.

	>> post.headers[:title] = "A change of title."
	=> "A change of title."
	
	>> post.headers[:title]
	=> { :title => "A change of title." }

And changes will carry through:

	>> post.headers.to_s
	=> "Title: A change of title.\nTags: redhead, ruby, headers"

## Objects themselves

Alternatively, you can work with the header name-value object itself.

	>> title_header = post.headers[:title]
	=> { :title => "A change of title." }
	
	>> title_header.value = "A better title."
	=> "A better title."
	
	>> title_header
	=> { :title => "A better title." }
	
	>> title_header.to_s
	=> "Title: A better title."

## Adding

You can also create and add new headers, in a similar way to modifying an existing header.

	>> post.headers[:awesome] = "very"
	=> "very"
	
	>> post.headers
	=> { { :title => "A better title." }, { :tags => "redhead, ruby, headers" }, { :awesome => "very" } }
	
	>> post.headers.to_s
	=> "Title: A better title.\nTags: redhead, ruby, headers\nAwesome: very"

Since Ruby assignments always return the right-hand side, there is an alternative syntax which will return the created header.

	>> post.headers.add(:amount_of_awesome, "high")
	=> { :amount_of_awesome => "high" }
	
	>> post.headers[:amount_of_awesome].to_s
	=> "Amount-Of-Awesome: high"

## Deleting

Deleting headers is just as easy.

	>> post.headers
	=> { { :title => "A better title." }, { :tags => "redhead, ruby, headers" }, { :awesome => "very" }, { :amount_of_awesome => "high" } }
	
	>> post.headers.delete(:amount_of_awesome)
	=> { :amount_of_awesome => "high" }
	
	>> post.headers
	=> { { :title => "A better title." }, { :tags => "redhead, ruby, headers" }, { :awesome => "very" } }

# Finer points

There are conventions followed in creating a Redhead string and modifying certain values.

## Names and `:symbols`

By default, newly added header field names (i.e., the keys) will become capitalised and hyphen-separated to create their raw header name, so that the symbolic header name `:if_modified_since` becomes the raw header name `If-Modified-Since`. A similar process also happens when turning a string into a Redhead string (in reverse), and when using the default behaviour of `to_s`. To keep symbol names pleasant, by default, anything which isn't `A-Z`, `a-z` or `_` is converted into a `_` character. So `"Some! Long! Header! Name!"` becomes `:some_long_header_name` for accessing within Ruby.

For information on changing the formatting rules, see the section on <a href="#special_circumstances">special circumstances</a>.

## Header name memory

Original header names are remembered from the input string, and not simply created on-the-fly when using `to_s`. This is to make sure you get the same raw heading name, as a string, that you originally read in, instead of assuming you want it to be changed. Access as a Ruby object, however, is with a symbol by default.

If the original string is:

	WaCKY fieLd NaME: value
	
	String's content.

Then the header will be turned into a symbol:

	>> str.headers
	=> { { :wacky_field_name => "value" } }

But `to_s` will give the original:

	>> str.headers.to_s
	=> "WaCKY fieLd NaME: value"

If this had been dynamically produced, it would return `Wacky-Field-Name` by default.

If you'd prefer to just let Redhead give you a header name it produces, based off the symbolic header name, use `to_s!`:

	>> str.headers.to_s!
	=> "Wacky-Field-Name: value"

For more on this, see below.

<h2 id="special_circumstances">Special circumstances</h2>

While the default conventions should suit you, you may need to break them. This is for you.

## Caveats

Redhead has two main conversions which take place, related to header names. One is to convert a raw header name to what is by default a symbol, the other is to convert from the symbol back to the string, where necessary, for example when using `to_s!`. There may be unexpected behaviour if the symbolic header name does not convert to a raw header name, and back again, i.e., in pseudocode, if `to_symbolic_header_name(to_raw_header_name(some_header.key)) != some_header.key`.

	>> str.headers
	=> { { :awesome_rating => "quite" } }
	
	>> output = str.headers.to_s(:awesome_rating => "Something-Completely-Different") + "\n\n" + str.to_s
	=> "Something-Completely-Different: quite\n\nString's content."
	
	>> input = Redhead::String[output]
	=> "String's content."
	
	>> input.headers
	=> { { :something_completely_different => "quite" } }
	
	>> input.headers[:awesome_rating]
	=> nil

(See below for this use of `to_s`.)

There will, however, eventually be a situation where the raw header name needs a better symbolic reference name, or vice versa.

With the above caveats in mind, to actually change the raw header name, you can work with the header itself.

	>> str.headers[:awesome] = "quite"
	=> "quite"
	
	>> awesome_header = str.headers[:awesome]
	=> { :awesome => "quite" }
	
	>> awesome_header.raw = "Some-Awe"
	=> "Some-Awe"
	
	>> awesome_header
	=> { :awesome => "quite" }
	
	>> awesome_header.to_s
	=> "Some-Awe: quite"
	
	>> str.headers.to_s
	=> "Some-Awe: quite"

You can also change the symbolic header name in the same fashion.

	# Delete to forget about the above
	>> str.headers.delete(:awesome)
	=> { :awesome => "quite" }
	
	>> str.headers[:awesome] = "quite"
	=> "quite"
	
	>> awesome_header = str.headers[:awesome]
	=> { :awesome => "quite" }
	
	>> awesome_header.key = :different_kind_of_awesome
	=> :different_kind_of_awesome
	
	>> awesome_header
	=> { :different_kind_of_awesome => "quite" }
	
	>> awesome_header.to_s
	=> "Awesome: quite"

The original symbolic header name will no longer work.

	>> str.headers[:awesome]
	=> nil
	
	>> str.headers[:different_kind_of_awesome].key = :awesome
	=> :awesome
	
	>> awesome_header
	=> { :awesome => "quite" }
	
	>> awesome_header.to_s
	=> "Awesome: quite"
	
	>> str.headers[:different_kind_of_awesome]
	=> nil

As a further option, there is `headers!`, which allows more one-step control, working with a hash argument. All _changed_ headers are returned.

	>> str.headers
	=> { { :awesome => "quite" } }
	
	>> str.headers[:temp] = "temp"
	=> "temp"
	
	>> str.headers
	=> { { :awesome => "quite" }, { :temp => "temp" } }
	
	>> str.headers.to_s
	=> "Some-Awe: quite\nTemp: temp"
	
	>> str.headers!(:awesome => { :key => :awesome_rating, :raw => "Awesome-Rating" })
	=> { { :awesome_rating => "quite" } }
	
	>> str.headers
	=> { { :awesome => "quite" }, { :temp => "temp" } }

Omitting one of `:raw` and `:key` will work as you expect.

## Non-destructive raw header changes

To work with a different raw header name, without modifying anything, you can pass a hash to `to_s`. This does not leave a side-effect and is only temporary.

	>> str.headers
	=> { { :awesome => "quite" }, { :temp => "temp" } }
	
	>> str.headers.to_s
	=> "Awesome-Rating: quite\nTemp: temp"
	
	>> str.headers.to_s(:awesome => "Something-To-Do with Awesome-ness", :temp => "A very TEMPORARY header name")
	=> "Something-To-Do with Awesome-ness: quite\nA very TEMPORARY header name"
	
	# Nothing changed.
	>> str.headers
	=> { { :awesome => "quite" }, { :temp => "temp" } }
	
	>> str.headers.to_s
	=> "Awesome-Rating: quite\nTemp: temp"

## Mismatching at creation

The custom raw header name can also be given explicitly at creation time.

	>> str.headers
	=> { { :awesome => "quite" }, { :temp => "temp" } }
	
	>> str.headers.delete(:temp)
	=> { :temp => "temp" }
	
	>> str.headers
	=> { { :awesome => "quite" } }
	
	>> str.heders.add(:temporary, "temp", "A-Rather-Temporary-Value")
	=> { :temp => "temp" }
	
	>> str.headers.to_s
	=> "Awesome-Rating: quite\nA-Rather-Temporary-Value: temp"

# Enterprise Header Solutions

As mentioned, Redhead performs two conversions. One to produce a symbolic header name from the raw header name, and one to produce the raw header name from the symbolic header name. The symbolic -> raw process is used in `to_s!`, to force header names to be produced instead of using the header name remembered from when the header was created.

If you need to control the format of header names beyond the simple separator option given above, you can provide a block, the result of which is the name used for the raw or symbolic header name.

If that doesn't make a lot of sense on the first read, don't worry, here's some code.

	>> string = "A-Header-Name: a header value\n\nContent."
	=> "A-Header-Name: a header value\n\nContent."
	
	>> str = Redhead::String.new(string) do |name|
	?>   name.split(/-/).join("").upcase.to_sym
	?> end
	=> +"Content."
	
	>> str.headers
	=> { { :AHEADERNAME => "a header value" } }

Note that this uses `Redhead::String.new` instead of `Redhead::String.[]` because of the block argument.

The above defines how symbolic headers are created in when creating the header objects. Using this approach, you can work with non-standard headers quite easily.

Note that `to_sym` is _not_ implicit, to suggest you use a pleasant symbol as the key.

It's also possible to specify the code to be used when calling `to_s`:

	>> str.headers
	=> { { :AHEADERNAME => "a header value" } }
	
	>> str.headers.to_s do |name|
	?>   name.to_s.downcase.scan(/..?.?/).join("-").capitalize
	?> end
	=> "ahe-ade-rna-me: a header value"

The block to `to_s` will not modify the headers in-place, in keeping with the behaviour of the block-less `to_s`. To change how the symbolic-to-raw header name conversion works, you can do so on the object holding the headers.

	>> str.headers.to_raw = lambda do |name|
	?>   name.to_s.downcase.scan(/..?.?/).join("-").capitalize
	?> end
	=> #<Proc:...>

Similarly, you can modify `to_key`. You can also change `to_raw` and `to_key` for each individual header. If no block is given for a specific header, it defaults to the block for the containing `headers` object. If nothing is given _there_, then it goes to the default.

If `to_raw(produced_key) != original_key` for all the headers in the object, then the headers are in a mismatched state. Equally, a single header is in a mismatched state if the condition fails for that header.

This can be checked with `reversible?`.

	>> string = "A-Header-Name: a header value\n\nContent."
	=> "A-Header-Name: a header value\n\nContent."
	
	>> str = Redhead::String.new(string) do |name|
	?>   name.gsub(/-/, "").upcase.to_sym
	?> end
	=> +"Content."
	
	# At this point, `to_key` is not reversible via `to_raw`
	
	>> str.headers.reversible?
	=> false
	
	>> str = Redhead::String.new(string) do |name|
	?>   name.split(/-/).map { |e| e.upcase }.join("zzz").to_sym
	?> end
	=> +"Content."
	
	>> str.headers
	=> { { :AzzzHEADERzzzNAME => "a header value" } }
	
	>> str.headers.reversible?
	=> false
	
	>> str.headers.to_raw = lambda do |name|
	?>   name.to_s.split(/zzz/).map { |e| e.capitalize }.join("-")
	?> end
	=> #<Proc:...> 
	
	# We can go back and forth without issue on this string
	
	>> str.headers.reversible?
	=> true
	
	>> str.headers
	=> { { :AzzzHEADERzzzzNAME => "a header value" } }
	
	>> str.headers.to_s
	=> "A-Header-Name: a header value"

Reversibility is checked by calling `reversible?` on all the headers in `str.headers`, since each header can have its own `to_key` and `to_raw` blocks. `reversible?` returning false will not raise an error or stop execution.

When creating new headers, `to_raw`, is used, meaning your custom block will be picked up and used to create the raw header as though it had been created from a string.

	>> str.headers.to_raw = proc { "Genuinely" }
	
	>> str.headers[:foo_bar] = "temp"
	=> "temp"
	
	>> temp_header = str.headers[:foo_bar]
	=> { :foo_bar => "temp" }
	
	>> temp_header.to_s
	=> "Genuinely: temp"

Changing `to_raw` after-the-fact will not change the raw header name stored for the object. To force `to_raw` to be used instead of the stored value, use `to_s!`, which _always_ uses `to_raw`.

	>> temp_header.to_raw = lambda { "nothing meaningful" }
	=> #<Proc:...>
	
	>> temp_header.to_s
	=> "Temp-Orary-Header: temp"
	
	>> temp_header.to_s!
	=> "nothing meaningful: temp"

# TODO

Headers on different lines with the same raw name. Important for HTTP.

Improve docs.
