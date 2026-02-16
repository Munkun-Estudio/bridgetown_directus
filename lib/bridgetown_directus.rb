# frozen_string_literal: true

require "bridgetown"
require_relative "bridgetown_directus/utils"
require_relative "bridgetown_directus/client"
require_relative "bridgetown_directus/data_mapper"
require_relative "bridgetown_directus/configuration"
require_relative "bridgetown_directus/builder"

module BridgetownDirectus
  # Bridgetown initializer for the plugin.
  #
  # Usage in config/initializers.rb:
  #
  #   init :bridgetown_directus do
  #     api_url ENV["DIRECTUS_API_URL"]
  #     token   ENV["DIRECTUS_API_TOKEN"]
  #   end
  #
  # Then configure collections separately:
  #
  #   BridgetownDirectus.configure do |directus|
  #     directus.register_collection(:posts) { |c| ... }
  #   end
  #
  Bridgetown.initializer :bridgetown_directus do |config, **kwargs|
    bd_config = Configuration.instance

    # Apply keyword args from init block (e.g. api_url, token)
    bd_config.api_url ||= kwargs[:api_url]&.to_s || ENV["DIRECTUS_API_URL"]
    bd_config.token   ||= kwargs[:token]&.to_s || ENV["DIRECTUS_API_TOKEN"] || ENV["DIRECTUS_TOKEN"]

    # Store on the Bridgetown config so the Builder can access it
    config.bridgetown_directus = bd_config

    # Register the builder
    config.builder BridgetownDirectus::Builder
  end

  # Global configuration singleton. Call BridgetownDirectus.configure to register collections.
  class Configuration
    attr_accessor :api_url, :token, :ssl_verify
    attr_reader :collections

    def initialize
      @collections = {}
      @ssl_verify = true
    end

    # Returns the singleton Configuration instance
    def self.instance
      @instance ||= new
    end

    # Reset the singleton (useful in tests)
    def self.reset!
      @instance = nil
    end

    def register_collection(name, &block)
      collection = CollectionConfig.new(name)
      collection.instance_eval(&block) if block_given?
      @collections[name] = collection
      collection
    end
  end

  # Configure the plugin. Call this after `init :bridgetown_directus`.
  #
  #   BridgetownDirectus.configure do |directus|
  #     directus.api_url = ENV["DIRECTUS_API_URL"]
  #     directus.register_collection(:posts) { |c| ... }
  #   end
  #
  def self.configure
    yield Configuration.instance if block_given?
  end
end
