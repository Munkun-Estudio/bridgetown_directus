# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/bridgetown_directus/configuration"

module BridgetownDirectus
  class ConfigurationTest < Minitest::Test
    def setup
      @config = Configuration.new
    end

    def test_register_collection
      @config.register_collection(:posts) do |c|
        c.endpoint = "articles"
        c.fields = { title: "title", content: "body" }
        c.default_query = { filter: { status: { _eq: "published" } } }
      end

      assert_equal 1, @config.collections.size
      assert @config.collections.key?(:posts)
      assert_equal "articles", @config.collections[:posts].endpoint
      assert_equal({ title: "title", content: "body" }, @config.collections[:posts].fields)
    end

    def test_field_with_converter
      @config.register_collection(:posts) do |c|
        c.field :title, "title"
        c.field :date, "published_at" do |value|
          Time.parse(value) if value
        end
      end

      assert_equal 1, @config.collections.size

      fields = @config.collections[:posts].fields
      assert_equal 2, fields.size

      assert fields[:title].is_a?(Hash)
      assert_equal "title", fields[:title][:directus_field]

      assert fields[:date].is_a?(Hash)
      assert_equal "published_at", fields[:date][:directus_field]
      assert fields[:date][:converter].is_a?(Proc)
    end

    def test_translations
      @config.register_collection(:posts) do |c|
        c.endpoint = "articles"
        c.enable_translations([:title, :content])
      end

      assert @config.collections[:posts].translations_enabled
      assert_equal [:title, :content], @config.collections[:posts].translatable_fields
    end
  end
end
