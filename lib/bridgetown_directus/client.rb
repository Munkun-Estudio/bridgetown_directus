# frozen_string_literal: true

require "json"
require "faraday"

module BridgetownDirectus
  # Client for interacting with the Directus API
  class Client
    attr_reader :api_url, :token

    # Initialize a new Directus client
    # @param api_url [String] The Directus API URL
    # @param token [String] The Directus API token
    def initialize(api_url:, token:)
      @api_url = api_url
      @token = token

      return unless @token.nil? || @api_url.nil?

      raise StandardError, "Invalid Directus configuration: missing API token or URL"
    end

    # Fetch a collection from Directus
    # @param collection [String] The collection name
    # @param params [Hash] Query parameters
    # @return [Hash] The collection data
    def fetch_collection(collection, params = {})
      Utils.log_directus "Fetching collection: #{collection} with params: #{params}"

      response = connection.get("/items/#{collection}") do |req|
        req.params.merge!(prepare_params(params))
      end

      handle_response(response)
    end

    # Fetch a single item from a collection
    # @param collection [String] The collection name
    # @param id [String, Integer] The item ID
    # @param params [Hash] Query parameters
    # @return [Hash] The item data
    def fetch_item(collection, id, params = {})
      Utils.log_directus "Fetching item: #{collection}/#{id} with params: #{params}"

      response = connection.get("/items/#{collection}/#{id}") do |req|
        req.params.merge!(prepare_params(params))
      end

      handle_response(response)
    end

    # Fetch items with a filter
    # @param collection [String] The collection name
    # @param filter [Hash] Filter criteria
    # @param params [Hash] Additional query parameters
    # @return [Hash] The filtered items
    def fetch_items_with_filter(collection, filter, params = {})
      merged_params = params.merge(filter: filter)
      fetch_collection(collection, merged_params)
    end

    # Fetch related items
    # @param collection [String] The collection name
    # @param id [String, Integer] The item ID
    # @param relation [String] The relation field
    # @param params [Hash] Query parameters
    # @return [Hash] The related items
    def fetch_related_items(collection, id, relation, params = {})
      Utils.log_directus "Fetching related items: #{collection}/#{id}/#{relation} with params: #{params}"

      response = connection.get("/items/#{collection}/#{id}/#{relation}") do |req|
        req.params.merge!(prepare_params(params))
      end

      handle_response(response)
    end

    private

    # Prepare query parameters for the API request
    # @param params [Hash] The query parameters
    # @return [Hash] The prepared parameters
    def prepare_params(params)
      prepared_params = {}

      # Handle filter parameters
      prepared_params[:filter] = params[:filter].to_json if params[:filter]

      # Handle sort parameters
      prepared_params[:sort] = params[:sort] if params[:sort]

      # Handle pagination
      prepared_params[:page] = params[:page] if params[:page]
      prepared_params[:limit] = params[:limit] if params[:limit]

      # Handle fields selection
      prepared_params[:fields] = params[:fields] if params[:fields]

      # Handle deep parameters (for related records)
      prepared_params[:deep] = params[:deep].to_json if params[:deep]

      # Merge any remaining parameters
      params.each do |key, value|
        next if [:filter, :sort, :page, :limit, :fields, :deep].include?(key)

        prepared_params[key] = value
      end

      prepared_params
    end

    # Create a Faraday connection with the appropriate headers
    # @return [Faraday::Connection] The connection
    def connection
      Faraday.new(url: @api_url) do |faraday|
        faraday.options.timeout = 10
        faraday.options.open_timeout = 5
        faraday.headers["Authorization"] = "Bearer #{@token}"
        faraday.headers["Content-Type"] = "application/json"
        faraday.adapter Faraday.default_adapter
      end
    end

    # Handle the API response
    # @param response [Faraday::Response] The API response
    # @return [Hash] The parsed response body
    def handle_response(response)
      if response.success?
        JSON.parse(response.body)
      elsif response.status == 401
        raise StandardError, "Unauthorized access to Directus API"
      else
        raise StandardError,
              "Error fetching data from Directus: #{response.status} - #{response.body}"
      end
    rescue Faraday::TimeoutError
      raise Faraday::TimeoutError, "The request to Directus API timed out"
    rescue JSON::ParserError
      raise JSON::ParserError, "The response from Directus was not valid JSON"
    end
  end
end
