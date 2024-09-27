# frozen_string_literal: true

require "bridgetown"
require_relative "bridgetown_directus/version"
require_relative "bridgetown_directus/utils"
require_relative "bridgetown_directus/api_client"
require_relative "bridgetown_directus/builder"

module BridgetownDirectus
  # Bridgetown initializer for the plugin
  Bridgetown.initializer :bridgetown_directus do |config, api_url:, token:|
    config.bridgetown_directus ||= {}
    config.bridgetown_directus.api_url ||= api_url || ENV.fetch("DIRECTUS_API_URL")
    config.bridgetown_directus.token ||= token || ENV.fetch("DIRECTUS_API_TOKEN")

    # Register the builder
    config.builder BridgetownDirectus::Builder

    # Validate Directus config before proceeding
    unless config.bridgetown_directus.api_url && config.bridgetown_directus.token
      Bridgetown.logger.error "Invalid Directus configuration detected. Please check your API URL and token."
      raise "Directus configuration invalid"
    end
  end
end
