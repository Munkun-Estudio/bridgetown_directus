# frozen_string_literal: true

require "minitest/autorun"
require "time"
require_relative "../../lib/bridgetown_directus/configuration"
require_relative "../../lib/bridgetown_directus/data_mapper"

module BridgetownDirectus
  class DataMapperTest < Minitest::Test
    def setup
      @config = Configuration.new
      @collection_config = @config.register_collection(:posts) do |c|
        c.endpoint = "articles"
        c.field :title, "title"
        c.field :content, "body"
        c.field :date, "published_at" do |value|
          value ? Time.parse(value).iso8601 : Time.now.iso8601
        end
        c.field :slug, "slug" do |value|
          value || "default-slug"
        end
      end
    end

    def test_map_basic_fields
      directus_data = {
        "id" => 1,
        "title" => "Test Article",
        "body" => "This is the content",
        "published_at" => "2025-04-09T10:00:00Z",
        "slug" => "test-article"
      }

      mapped_data = DataMapper.map(@collection_config, directus_data)

      assert_equal "Test Article", mapped_data[:title]
      assert_equal "This is the content", mapped_data[:content]
      assert_equal "2025-04-09T10:00:00Z", mapped_data[:date]
      assert_equal "test-article", mapped_data[:slug]
    end

    def test_map_with_missing_fields
      directus_data = {
        "id" => 2,
        "title" => "Another Article",
        "body" => "More content"
        # Missing published_at and slug
      }

      mapped_data = DataMapper.map(@collection_config, directus_data)

      assert_equal "Another Article", mapped_data[:title]
      assert_equal "More content", mapped_data[:content]
      assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, mapped_data[:date]) # Should be current time
      assert_equal "default-slug", mapped_data[:slug]
    end

    def test_map_translations
      # Configure translations
      @collection_config.enable_translations([:title, :content])

      directus_data = {
        "id" => 3,
        "title" => "English Title",
        "body" => "English content",
        "translations" => [
          {
            "languages_code" => "es",
            "title" => "Spanish Title",
            "body" => "Spanish content"
          },
          {
            "languages_code" => "fr",
            "title" => "French Title",
            "body" => "French content"
          }
        ]
      }

      # Map with Spanish locale
      es_mapped_data = DataMapper.map_translations(@collection_config, directus_data, :es)
      
      assert_equal "Spanish Title", es_mapped_data[:title]
      assert_equal "Spanish content", es_mapped_data[:content]
      assert_equal :es, es_mapped_data[:locale]

      # Map with French locale
      fr_mapped_data = DataMapper.map_translations(@collection_config, directus_data, :fr)
      
      assert_equal "French Title", fr_mapped_data[:title]
      assert_equal "French content", fr_mapped_data[:content]
      assert_equal :fr, fr_mapped_data[:locale]
    end
  end
end
