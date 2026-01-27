# frozen_string_literal: true

require "bridgetown"
require_relative "bridgetown_directus/utils"
require_relative "bridgetown_directus/client"
require_relative "bridgetown_directus/data_mapper"
require_relative "bridgetown_directus/configuration"
require_relative "bridgetown_directus/builder"

module BridgetownDirectus
  # Bridgetown initializer for the plugin
  Bridgetown.initializer :bridgetown_directus do |config|
    # Only assign config.bridgetown_directus if not already set
    config.bridgetown_directus ||= Configuration.new

    # Set up configuration directly (leave to user initializer if possible)
    config.bridgetown_directus.api_url ||= ENV["DIRECTUS_API_URL"]
    config.bridgetown_directus.token ||= ENV["DIRECTUS_API_TOKEN"] || ENV["DIRECTUS_TOKEN"]

    # Register the builder
    config.builder BridgetownDirectus::Builder
  end

  class Configuration
    attr_accessor :api_url, :token
    attr_reader :collections

    def initialize
      @collections = {}
    end

    def register_collection(name, &block)
      collection = CollectionConfig.new(name)
      collection.instance_eval(&block) if block_given?
      @collections[name] = collection
      collection
    end
  end
end
