# Copyright (c) 2010 Adam Prescott
# Licensed under the MIT license. See LICENSE.

module Redhead
  
  # The character used to separate raw header names from their values.
  HEADER_NAME_VALUE_SEPARATOR_CHARACTER = ":"
  
  # The actual pattern to split header name from value. Uses the above character.
  HEADER_NAME_VALUE_SEPARATOR_PATTERN = /\s*#{HEADER_NAME_VALUE_SEPARATOR_CHARACTER}\s*/
  
  # The separator between header lines and regular body content.
  HEADERS_SEPARATOR = "\n\n"
  
  # The actual pattern used to split headers from content.
  HEADERS_SEPARATOR_PATTERN = /#{HEADERS_SEPARATOR}/m
  
  # The default code to convert a given key to a raw header name.
  TO_RAW = lambda { |key| key.to_s.split(/_/).map(&:capitalize).join("-") }
  
  # The default code to convert a given raw header name to a key.
  TO_KEY = lambda { |raw| raw.split(/[^a-z_]+/i).join("_").downcase.to_sym }
end

require "redhead/header"
require "redhead/header_set"
require "redhead/redhead_string"
