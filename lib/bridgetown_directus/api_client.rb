# frozen_string_literal: true

require 'faraday'
require 'json'

module BridgetownDirectus
  class APIClient
    def initialize(site)
      @site = site
      @api_url = site.config.bridgetown_directus.api_url
      @api_token = site.config.bridgetown_directus.token

      raise StandardError, "Invalid Directus configuration: missing API token or URL" if @api_token.nil? || @api_url.nil?
    end

    # Main method to fetch posts
    def fetch_posts
      Utils.log_directus "Request URL: #{@api_url}"
      begin
        response = connection.get("/items/posts") do |req|
          req.params['filter'] = { status: { _eq: "published" } }.to_json
        end

        if response.success?
          JSON.parse(response.body)  # Return the parsed posts
        elsif response.status == 401
          raise RuntimeError, "Unauthorized access to Directus API"
        else
          raise "Error fetching posts: #{response.status} - #{response.body}"
        end
      rescue Faraday::TimeoutError
        raise Faraday::TimeoutError, "The request to fetch posts timed out"
      rescue JSON::ParserError
        raise JSON::ParserError, "The response from Directus was not valid JSON"
      end
    end

    # Setup Faraday connection with authorization headers
    def connection
      Faraday.new(url: @api_url) do |faraday|
        faraday.options.timeout = 5           # seconds
        faraday.options.open_timeout = 2      # seconds
        faraday.headers['Authorization'] = "Bearer #{@api_token}"
        faraday.headers['Content-Type'] = 'application/json'
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
