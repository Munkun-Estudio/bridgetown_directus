# frozen_string_literal: true

require "minitest/autorun"
require "webmock/minitest"
require "json"
require "faraday"
require_relative "../../lib/bridgetown_directus/utils"
require_relative "../../lib/bridgetown_directus/client"

module BridgetownDirectus
  class ClientTest < Minitest::Test
    def setup
      @api_url = "https://directus.example.com"
      @token = "test_token"
      @client = Client.new(api_url: @api_url, token: @token)
      
      # Stub the logger to avoid actual logging during tests
      BridgetownDirectus::Utils.singleton_class.class_eval do
        alias_method :original_log_directus, :log_directus
        def self.log_directus(msg)
          # Do nothing in tests
        end
      end
    end
    
    def teardown
      # Restore the original logger method
      BridgetownDirectus::Utils.singleton_class.class_eval do
        alias_method :log_directus, :original_log_directus if method_defined?(:original_log_directus)
      end
    end

    def test_fetch_collection
      stub_request(:get, "#{@api_url}/items/posts")
        .with(
          headers: {
            'Authorization' => "Bearer #{@token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: { data: [{ id: 1, title: "Test Post" }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = @client.fetch_collection("posts")
      assert response.is_a?(Array)
      assert_equal 1, response.first["id"]
    end

    def test_fetch_collection_with_params
      stub_request(:get, "#{@api_url}/items/posts")
        .with(
          headers: {
            'Authorization' => "Bearer #{@token}",
            'Content-Type' => 'application/json'
          },
          query: hash_including("filter" => { "status" => { "_eq" => "published" } })
        )
        .to_return(
          status: 200,
          body: { data: [{ id: 1, title: "Published Post" }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = @client.fetch_collection("posts", { filter: { status: { _eq: "published" } } })
      assert response.is_a?(Array)
      assert_equal "Published Post", response.first["title"]
    end

    def test_fetch_item
      stub_request(:get, "#{@api_url}/items/posts/1")
        .with(
          headers: {
            'Authorization' => "Bearer #{@token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: { data: { id: 1, title: "Test Post" } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = @client.fetch_item("posts", 1)
      assert response.is_a?(Hash)
      assert_equal 1, response["id"]
      assert_equal "Test Post", response["title"]
    end

    def test_unauthorized_error
      stub_request(:get, "#{@api_url}/items/posts")
        .to_return(
          status: 401,
          body: { error: { message: "Unauthorized" } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      assert_raises(RuntimeError) do
        @client.fetch_collection("posts")
      end
    end

    def test_timeout_error
      stub_request(:get, "#{@api_url}/items/posts")
        .to_timeout

      error = assert_raises do
        @client.fetch_collection("posts")
      end
      assert [Faraday::TimeoutError, Faraday::ConnectionFailed].include?(error.class),
             "Expected a timeout error but got #{error.class.name}"
    end
  end
end
