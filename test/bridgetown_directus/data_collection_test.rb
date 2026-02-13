# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/bridgetown_directus/builder"
require_relative "../../lib/bridgetown_directus/configuration"

# Structs for minimal site stubbing
DataCollectionSiteConfig = Struct.new(:bridgetown_directus)
DataCollectionDirectusConfig = Struct.new(:api_url)

class DataCollectionSite
  attr_accessor :source, :config, :data

  def initialize(source:, config:)
    @source = source
    @config = config
    @data = {}
  end
end

class DataCollectionTest < Minitest::Test
  def setup
    @site = DataCollectionSite.new(
      source: Dir.mktmpdir,
      config: DataCollectionSiteConfig.new(DataCollectionDirectusConfig.new("https://cms.example.com"))
    )
    @builder = BridgetownDirectus::Builder.new
    @builder.site = @site
  end

  def teardown
    FileUtils.remove_entry @site.source
  end

  # --- CollectionConfig: data? and singleton ---

  def test_data_resource_type
    config = BridgetownDirectus::Configuration::CollectionConfig.new(:settings)
    config.resource_type = :data
    assert config.data?
    refute config.singleton
  end

  def test_singleton_config
    config = BridgetownDirectus::Configuration::CollectionConfig.new(:settings)
    config.resource_type = :data
    config.singleton = true
    assert config.data?
    assert config.singleton
  end

  def test_non_data_resource_type
    config = BridgetownDirectus::Configuration::CollectionConfig.new(:posts)
    config.resource_type = :posts
    refute config.data?
  end

  # --- CollectionConfig: flatten_m2m ---

  def test_flatten_m2m_registration
    config = BridgetownDirectus::Configuration::CollectionConfig.new(:pages)
    config.flatten_m2m "sections.stats", key: "raus_stats_id"
    config.flatten_m2m "sections.faqs", key: "raus_faqs_id"

    assert_equal 2, config.m2m_flattenings.size
    assert_equal({ path: "sections.stats", key: "raus_stats_id" }, config.m2m_flattenings[0])
    assert_equal({ path: "sections.faqs", key: "raus_faqs_id" }, config.m2m_flattenings[1])
  end

  # --- Builder: process_data_collection (singleton) ---

  def test_process_data_collection_singleton
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:site_settings)
    collection_config.resource_type = :data
    collection_config.singleton = true
    collection_config.endpoint = "raus_site_settings"

    # Directus returns singletons as a single-element array
    response = [{ "id" => 1, "site_name" => "RAUS", "contact_email" => "info@raus.es" }]

    @builder.send(:process_data_collection_with_data, response, collection_config)

    result = @site.data["site_settings"]
    assert result.is_a?(Hash)
    assert_equal "RAUS", result["site_name"]
    assert_equal "info@raus.es", result["contact_email"]
  end

  # --- Builder: process_data_collection (list) ---

  def test_process_data_collection_list
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:navigation_items)
    collection_config.resource_type = :data
    collection_config.endpoint = "raus_navigation_items"

    response = [
      { "id" => 1, "title" => "Inicio", "url" => "/" },
      { "id" => 2, "title" => "La RAUS", "url" => "/la-raus/" },
    ]

    @builder.send(:process_data_collection_with_data, response, collection_config)

    result = @site.data["navigation_items"]
    assert result.is_a?(Array)
    assert_equal 2, result.size
    assert_equal "Inicio", result[0]["title"]
  end

  # --- Builder: flatten_m2m ---

  def test_flatten_m2m_on_nested_data
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:pages)
    collection_config.resource_type = :data
    collection_config.flatten_m2m "sections.stats", key: "raus_stats_id"

    data = [
      {
        "id" => 1,
        "title" => "Home",
        "sections" => [
          {
            "id" => 10,
            "type" => "stats",
            "stats" => [
              { "raus_stats_id" => { "id" => 100, "value" => "8+", "label" => "Disciplinas" } },
              { "raus_stats_id" => { "id" => 101, "value" => "50+", "label" => "Miembros" } },
            ],
          },
        ],
      },
    ]

    @builder.send(:apply_m2m_flattenings!, data, collection_config)

    stats = data[0]["sections"][0]["stats"]
    assert_equal 2, stats.size
    assert_equal({ "id" => 100, "value" => "8+", "label" => "Disciplinas" }, stats[0])
    assert_equal({ "id" => 101, "value" => "50+", "label" => "Miembros" }, stats[1])
  end

  def test_flatten_m2m_filters_nil_junctions
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:pages)
    collection_config.resource_type = :data
    collection_config.flatten_m2m "sections.stats", key: "raus_stats_id"

    data = [
      {
        "sections" => [
          {
            "stats" => [
              { "raus_stats_id" => { "id" => 100, "value" => "8+" } },
              { "raus_stats_id" => nil },
            ],
          },
        ],
      },
    ]

    @builder.send(:apply_m2m_flattenings!, data, collection_config)

    stats = data[0]["sections"][0]["stats"]
    assert_equal 1, stats.size
    assert_equal 100, stats[0]["id"]
  end

  def test_flatten_m2m_multiple_relations
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:pages)
    collection_config.resource_type = :data
    collection_config.flatten_m2m "sections.stats", key: "raus_stats_id"
    collection_config.flatten_m2m "sections.faqs", key: "raus_faqs_id"

    data = [
      {
        "sections" => [
          {
            "stats" => [{ "raus_stats_id" => { "id" => 1, "value" => "8+" } }],
            "faqs" => [{ "raus_faqs_id" => { "id" => 2, "question" => "Why?" } }],
          },
        ],
      },
    ]

    @builder.send(:apply_m2m_flattenings!, data, collection_config)

    assert_equal({ "id" => 1, "value" => "8+" }, data[0]["sections"][0]["stats"][0])
    assert_equal({ "id" => 2, "question" => "Why?" }, data[0]["sections"][0]["faqs"][0])
  end

  def test_flatten_m2m_noop_when_no_flattenings
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:nav)
    collection_config.resource_type = :data

    data = [{ "id" => 1, "title" => "Home" }]
    original = data.dup

    @builder.send(:apply_m2m_flattenings!, data, collection_config)

    assert_equal original, data
  end

  def test_flatten_m2m_on_singleton
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:page)
    collection_config.resource_type = :data
    collection_config.singleton = true
    collection_config.flatten_m2m "sections.stats", key: "raus_stats_id"

    data = {
      "id" => 1,
      "sections" => [
        {
          "stats" => [
            { "raus_stats_id" => { "id" => 100, "value" => "8+" } },
          ],
        },
      ],
    }

    @builder.send(:apply_m2m_flattenings!, data, collection_config)

    assert_equal({ "id" => 100, "value" => "8+" }, data["sections"][0]["stats"][0])
  end
end
