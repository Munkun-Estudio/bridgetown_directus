# frozen_string_literal: true

require "bridgetown"
require_relative "bridgetown_directus/utils"
require_relative "bridgetown_directus/api_client"
require_relative "bridgetown_directus/builder"

module BridgetownDirectus
  # Bridgetown initializer for the plugin
  Bridgetown.initializer :bridgetown_directus do |config, api_url:, token:, collection:, mappings:|
    config.bridgetown_directus ||= {}
    config.bridgetown_directus.api_url ||= api_url || ENV.fetch("DIRECTUS_API_URL")
    config.bridgetown_directus.token ||= token || ENV.fetch("DIRECTUS_API_TOKEN")

    # Access collection and mappings from the bridgetown.config.yml
    config.bridgetown_directus.collection ||= config.directus.collection
    config.bridgetown_directus.mappings ||= config.directus.mappings
    config.bridgetown_directus.translations ||= config.directus["translations"]

    # Register the builder
    config.builder BridgetownDirectus::Builder

    # Log translations status
    if config.bridgetown_directus.translations["enabled"]
      translatable_fields = config.bridgetown_directus.translations["fields"] || []
      Bridgetown.logger.info "Directus translations enabled for fields: #{translatable_fields.join(', ')}"
    else
      Bridgetown.logger.info "Directus translations are disabled"
    end

    # Validate Directus config before proceeding
    unless config.bridgetown_directus.api_url && config.bridgetown_directus.token
      Bridgetown.logger.error "Invalid Directus configuration detected. Please check your API URL and token."
      raise "Directus configuration invalid"
    end
  end
end
