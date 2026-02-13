# frozen_string_literal: true

require "minitest/autorun"
require "ostruct"

# Mock Bridgetown::Builder for plugin unit testing (if Bridgetown isn't loaded)
unless defined?(Bridgetown)
  module Bridgetown
    class Builder
      attr_accessor :site
    end
  end
end
