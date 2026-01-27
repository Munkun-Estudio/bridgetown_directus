# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/bridgetown_directus/builder"
require_relative "../../lib/bridgetown_directus/configuration"

BridgetownDirectusConfig = Struct.new(:api_url)
SiteConfig = Struct.new(:bridgetown_directus)
Site = Struct.new(:source, :config)

class BuilderTest < Minitest::Test
  def setup
    # Minimal stub for site config using Structs (no OpenStruct)
    @site = Site.new(
      Dir.mktmpdir,
      SiteConfig.new(BridgetownDirectusConfig.new("https://cms.example.com"))
    )
    @builder = BridgetownDirectus::Builder.new
    @builder.instance_variable_set(:@site, @site)
    @collection_dir = File.join(@site.source, "_custom")
  end

  def teardown
    FileUtils.remove_entry @site.source
  end

  def test_build_filename
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:posts)
    collection_config.resource_type = :posts
    item = { "date" => "2025-01-02", "slug" => "my-slug" }
    filename = @builder.send(:build_filename, @collection_dir, collection_config, item, "my-slug")
    assert_equal File.join(@collection_dir, "2025-01-02-my-slug.md"), filename
  end

  def test_transform_item_fields_with_image_id
    item = { "image" => "abc123", "title" => "Test" }
    result = @builder.send(:transform_item_fields, item, "https://cms.example.com", "material")
    assert_equal "https://cms.example.com/assets/abc123", result["image"]
    assert_equal "material", result["layout"]
  end

  def test_transform_item_fields_with_full_image_url
    item = { "image" => "https://cdn.example.com/img.jpg", "title" => "Test" }
    result = @builder.send(:transform_item_fields, item, "https://cms.example.com", "material")
    assert_equal "https://cdn.example.com/img.jpg", result["image"]
  end

  def test_generate_front_matter
    item = { "title" => "Hello", "layout" => "material", "image" => "img.jpg" }
    yaml = @builder.send(:generate_front_matter, item)
    assert_match(%r{title: Hello}, yaml)
    assert_match(%r{layout: material}, yaml)
    assert_match(%r{image: img.jpg}, yaml)
    refute_match(%r{^---}, yaml)
  end

  def test_write_markdown_file_and_content
    filename = File.join(@site.source, "test.md")
    front_matter = "title: Test\nlayout: material\n"
    content = "This is the content."
    payload = @builder.send(:render_markdown, front_matter, content)
    @builder.send(:write_markdown_file, filename, payload)
    output = File.read(filename)
    assert_match(%r{^---\ntitle: Test}, output)
    assert_match(%r{This is the content\.}, output)
  end

  def test_write_directus_file_creates_file_with_expected_content
    item = {
      "slug"  => "sample-material",
      "title" => "Sample Material",
      "image" => "imgid",
      "body"  => "Body content.",
    }
    collection_config = BridgetownDirectus::Configuration::CollectionConfig.new(:custom)
    collection_config.layout = "material"
    collection_config.resource_type = :custom_collection
    file, payload = @builder.send(
      :build_directus_payload,
      item,
      @collection_dir,
      collection_config,
      "https://cms.example.com"
    )
    @builder.send(:write_markdown_file, file, payload)
    file = File.join(@collection_dir, "sample-material.md")
    assert File.exist?(file)
    text = File.read(file)
    assert_match(%r{title: Sample Material}, text)
    assert_match(%r{layout: material}, text)
    assert_match(%r{image: https://cms.example.com/assets/imgid}, text)
    assert_match(%r{Body content\.}, text)
    assert_match(%r{directus_generated: true}, text)
  end

  def test_clean_collection_directory_removes_only_generated_md_files
    FileUtils.mkdir_p(@collection_dir)
    user_file = File.join(@collection_dir, "user.md")
    File.write(user_file, "---\ntitle: User File\n---\nContent")
    gen_file = File.join(@collection_dir, "gen.md")
    File.write(gen_file, "---\ndirectus_generated: true\n---\nContent")
    @builder.send(:clean_collection_directory, @collection_dir)
    assert File.exist?(user_file), "User file should not be deleted"
    refute File.exist?(gen_file), "Generated file should be deleted"
  end
end
