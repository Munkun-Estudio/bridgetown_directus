# frozen_string_literal: true

require "json"
require "faraday"

module BridgetownDirectus
  # Client for interacting with the Directus API
  class Client
    attr_reader :api_url, :token

    def initialize(api_url:, token:, ssl_verify: true)
      @api_url = api_url
      @token = token
      @ssl_verify = ssl_verify
      return unless @token.nil? || @api_url.nil?

      raise StandardError, "Invalid Directus configuration: missing API token or URL"
    end

    def fetch_collection(collection, params = {})
      response = connection.get("/items/#{collection}") do |req|
        req.params.merge!(prepare_params(params))
      end
      handle_response(response)
    end

    def fetch_item(collection, id, params = {})
      response = connection.get("/items/#{collection}/#{id}") do |req|
        req.params.merge!(prepare_params(params))
      end
      handle_response(response)
    end

    def fetch_items_with_filter(collection, filter, params = {})
      merged_params = params.merge(filter: filter)
      fetch_collection(collection, merged_params)
    end

    def fetch_related_items(collection, id, relation, params = {})
      response = connection.get("/items/#{collection}/#{id}/#{relation}") do |req|
        req.params.merge!(prepare_params(params))
      end
      handle_response(response)
    end

    private

    def connection
      @connection ||= Faraday.new(url: @api_url, ssl: { verify: @ssl_verify }) do |faraday|
        faraday.headers["Authorization"] = "Bearer #{@token}"
        faraday.headers["Content-Type"] = "application/json"
        faraday.adapter Faraday.default_adapter
      end
    end

    def prepare_params(params)
      params.transform_keys(&:to_s)
    end

    def handle_response(response)
      unless response.success?
        Utils.log_directus "Directus API error: #{response.status} - #{response.body}"
        raise "Directus API error: #{response.status}"
      end
      json = JSON.parse(response.body)
      json["data"] || []
    rescue JSON::ParserError => e
      Utils.log_directus "Failed to parse Directus response: #{e.message}"
      raise
    end
  end
end
