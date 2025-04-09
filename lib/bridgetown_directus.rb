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
    # Create a new configuration instance
    config.bridgetown_directus = Configuration.new
    
    # Set API credentials from environment variables if not provided
    config.bridgetown_directus.api_url = ENV.fetch("DIRECTUS_API_URL", nil)
    config.bridgetown_directus.token = ENV.fetch("DIRECTUS_API_TOKEN", nil)
    
    # Register the builder
    config.builder BridgetownDirectus::Builder
    
    # Allow for configuration via a block
    yield config.bridgetown_directus if block_given?
    
    # Validate Directus config before proceeding
    unless config.bridgetown_directus.api_url && config.bridgetown_directus.token
      Bridgetown.logger.error "Invalid Directus configuration detected. Please check your API URL and token."
      raise "Directus configuration invalid"
    end
    
    # Log configuration status
    collection_count = config.bridgetown_directus.collections.size
    if collection_count > 0
      Bridgetown.logger.info "Directus: Configured #{collection_count} collections"
    else
      Bridgetown.logger.warn "Directus: No collections configured"
    end
  end
  
  # Add helper methods to Configuration class
  class Configuration
    attr_accessor :api_url, :token
  end
end
