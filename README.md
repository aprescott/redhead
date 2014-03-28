[![Build Status](https://travis-ci.org/aprescott/redhead.png?branch=master)](https://travis-ci.org/aprescott/redhead) [![Coverage Status](https://coveralls.io/repos/aprescott/redhead/badge.png)](https://coveralls.io/r/aprescott/redhead)

# What is it?

Redhead is for header metadata in strings, in the style of HTTP and email. It makes just a few assumptions about your header names and values, keeps them all as strings, and leaves the rest to you.

# License

MIT License. See LICENSE for details.

# How do I use this thing?

To install from RubyGems:

    gem install redhead

To get the source:

    git clone https://github.com/aprescott/redhead.git

To run the tests with the source:

    rake test

To contribute:

* Fork it
* Make a new feature branch: `git checkout -b some-new-thing master`
* Pull request

## Basics

A variable `post` referencing a simple string can be wrapped up in a `Redhead::String` object.

	>> puts post
	Title: Redhead is for headers!
	Tags: redhead, ruby, headers

	Since time immemorial, ...

	>> post = Redhead::String[post]
	=> +"Since time immemorial, ..."

	>> post.headers
	=> { { title: "Redhead is for headers" }, { tags: "redhead, ruby, headers" } }

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
	=> { { title: "Redhead is for headers" }, { tags: "redhead, ruby, headers" } }

	>> post.replace("Better content.")
	=> "Better content."

	>> post.to_s
	=> "Better content."

	>> post.headers
	=> { { title: "Redhead is for headers" }, { tags: "redhead, ruby, headers" } }

Note that `String` instance methods which are not receiver-modifying will return proper `String` instances, and so headers will be lost.

## Accessing

In addition, you get access to headers.

	>> post.headers[:title]
	=> { title: "Redhead is for headers!" }

	>> post.headers[:tags].to_s
	=> "redhead, ruby, headers"

	>> post.headers.to_s
	=> "Title: Redhead is for headers!\nTags: redhead, ruby, headers"

## Changing values

Modifying a header value is easy.

	>> post.headers[:title] = "A change of title."
	=> "A change of title."

	>> post.headers[:title]
	=> { title: "A change of title." }

And changes will carry through:

	>> post.headers.to_s
	=> "Title: A change of title.\nTags: redhead, ruby, headers"

## Objects themselves

Alternatively, you can work with the header name-value object itself.

	>> title_header = post.headers[:title]
	=> { title: "A change of title." }

	>> title_header.value = "A better title."
	=> "A better title."

	>> title_header
	=> { title: "A better title." }

	>> title_header.to_s
	=> "Title: A better title."

## Adding

You can also create and add new headers, in a similar way to modifying an existing header.

	>> post.headers[:awesome] = "very"
	=> "very"

	>> post.headers
	=> { { title: "A better title." }, { tags: "redhead, ruby, headers" }, { awesome: "very" } }

	>> post.headers.to_s
	=> "Title: A better title.\nTags: redhead, ruby, headers\nAwesome: very"

Since Ruby assignments always return the right-hand side, there is an alternative syntax which will return the created header.

	>> post.headers.add(:amount_of_awesome, "high")
	=> { amount_of_awesome: "high" }

	>> post.headers[:amount_of_awesome].to_s
	=> "Amount-Of-Awesome: high"

## Deleting

Deleting headers is just as easy.

	>> post.headers
	=> { { title: "A better title." }, { tags: "redhead, ruby, headers" }, { awesome: "very" }, { amount_of_awesome: "high" } }

	>> post.headers.delete(:amount_of_awesome)
	=> { amount_of_awesome: "high" }

	>> post.headers
	=> { { title: "A better title." }, { tags: "redhead, ruby, headers" }, { awesome: "very" } }

# Finer points

There are conventions followed in creating a Redhead string and modifying certain values.

## Names and `:symbols`

By default, newly added header field names (i.e., the keys) will become capitalised and hyphen-separated to create their raw header name, so that the symbolic header name `:if_modified_since` becomes the raw header name `If-Modified-Since`. A similar process also happens when turning a string into a Redhead string (in reverse), and when using the default behaviour of `to_s`. To keep symbol names pleasant, by default, anything which isn't `A-Z`, `a-z` or `_` is converted into a `_` character. So `"Some! Long! Header! Name!"` becomes `:some_long_header_name` for accessing within Ruby.

## Header name memory

Original header names are remembered from the input string, and not simply created on-the-fly when using `to_s`. This is to make sure you get the same raw heading name, as a string, that you originally read in, instead of assuming you want it to be changed. Access as a Ruby object, however, is with a symbol by default.

If the original string is:

	WaCKY fieLd NaME: value

	String's content.

Then the header will be turned into a symbol:

	>> str.headers
	=> { { wacky_field_name: "value" } }

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
	=> { { awesome_rating: "quite" } }

	>> output = str.headers.to_s(awesome_rating: "Something-Completely-Different") + "\n\n" + str.to_s
	=> "Something-Completely-Different: quite\n\nString's content."

	>> input = Redhead::String[output]
	=> "String's content."

	>> input.headers
	=> { { something_completely_different: "quite" } }

	>> input.headers[:awesome_rating]
	=> nil

(See below for this use of `to_s`.)

There will, however, eventually be a situation where the raw header name needs a better symbolic reference name, or vice versa.

With the above caveats in mind, to actually change the raw header name, you can work with the header itself.

	>> str.headers[:awesome] = "quite"
	=> "quite"

	>> awesome_header = str.headers[:awesome]
	=> { awesome: "quite" }

	>> awesome_header.raw = "Some-Awe"
	=> "Some-Awe"

	>> awesome_header
	=> { awesome: "quite" }

	>> awesome_header.to_s
	=> "Some-Awe: quite"

	>> str.headers.to_s
	=> "Some-Awe: quite"

You can also change the symbolic header name in the same fashion.

	# Delete to forget about the above
	>> str.headers.delete(:awesome)
	=> { awesome: "quite" }

	>> str.headers[:awesome] = "quite"
	=> "quite"

	>> awesome_header = str.headers[:awesome]
	=> { awesome: "quite" }

	>> awesome_header.key = :different_kind_of_awesome
	=> :different_kind_of_awesome

	>> awesome_header
	=> { different_kind_of_awesome: "quite" }

	>> awesome_header.to_s
	=> "Awesome: quite"

The original symbolic header name will no longer work.

	>> str.headers[:awesome]
	=> nil

	>> str.headers[:different_kind_of_awesome].key = :awesome
	=> :awesome

	>> awesome_header
	=> { awesome: "quite" }

	>> awesome_header.to_s
	=> "Awesome: quite"

	>> str.headers[:different_kind_of_awesome]
	=> nil

As a further option, there is `headers!`, which allows more one-step control, working with a hash argument. All _changed_ headers are returned.

	>> str.headers
	=> { { awesome: "quite" } }

	>> str.headers[:temp] = "temp"
	=> "temp"

	>> str.headers
	=> { { awesome: "quite" }, { temp: "temp" } }

	>> str.headers.to_s
	=> "Some-Awe: quite\nTemp: temp"

	>> str.headers!(awesome: { key: :awesome_rating, raw: "Awesome-Rating" })
	=> { { awesome_rating: "quite" } }

	>> str.headers
	=> { { awesome: "quite" }, { temp: "temp" } }

Omitting one of `:raw` and `:key` will work as you expect.

## Non-destructive raw header changes

To work with a different raw header name, without modifying anything, you can pass a hash to `to_s`. This does not leave a side-effect and is only temporary.

	>> str.headers
	=> { { awesome: "quite" }, { temp: "temp" } }

	>> str.headers.to_s
	=> "Awesome-Rating: quite\nTemp: temp"

	>> str.headers.to_s(awesome: "Something-To-Do with Awesome-ness", temp: "A very TEMPORARY header name")
	=> "Something-To-Do with Awesome-ness: quite\nA very TEMPORARY header name"

	# Nothing changed.
	>> str.headers
	=> { { awesome: "quite" }, { temp: "temp" } }

	>> str.headers.to_s
	=> "Awesome-Rating: quite\nTemp: temp"

## Mismatching at creation

The custom raw header name can also be given explicitly at creation time.

	>> str.headers
	=> { { awesome: "quite" }, { temp: "temp" } }

	>> str.headers.delete(:temp)
	=> { temp: "temp" }

	>> str.headers
	=> { { awesome: "quite" } }

	>> str.headers.add(:temporary, "temp", "A-Rather-Temporary-Value")
	=> { temp: "temp" }

	>> str.headers.to_s
	=> "Awesome-Rating: quite\nA-Rather-Temporary-Value: temp"

# TODO

Headers on different lines with the same raw name. Important for HTTP.

Improve docs.
