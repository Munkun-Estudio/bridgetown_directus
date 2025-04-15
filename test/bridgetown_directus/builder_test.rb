# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/bridgetown_directus/builder"

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
    @collection_dir = File.join(@site.source, "_posts")
  end

  def teardown
    FileUtils.remove_entry @site.source
  end

  def test_build_filename
    filename = @builder.send(:build_filename, @collection_dir, "my-slug")
    assert_equal File.join(@collection_dir, "my-slug.md"), filename
  end

  def test_transform_item_fields_with_image_id
    item = { "image" => "abc123", "title" => "Test" }
    result = @builder.send(:transform_item_fields, item, "https://cms.example.com", "post")
    assert_equal "https://cms.example.com/assets/abc123", result["image"]
    assert_equal "post", result["layout"]
  end

  def test_transform_item_fields_with_full_image_url
    item = { "image" => "https://cdn.example.com/img.jpg", "title" => "Test" }
    result = @builder.send(:transform_item_fields, item, "https://cms.example.com", "post")
    assert_equal "https://cdn.example.com/img.jpg", result["image"]
  end

  def test_generate_front_matter
    item = { "title" => "Hello", "layout" => "post", "image" => "img.jpg" }
    yaml = @builder.send(:generate_front_matter, item)
    assert_match(%r{title: Hello}, yaml)
    assert_match(%r{layout: post}, yaml)
    assert_match(%r{image: img.jpg}, yaml)
    refute_match(%r{^---}, yaml)
  end

  def test_write_markdown_file_and_content
    filename = File.join(@site.source, "test.md")
    front_matter = "title: Test\nlayout: post\n"
    content = "This is the content."
    @builder.send(:write_markdown_file, filename, front_matter, content)
    output = File.read(filename)
    assert_match(%r{^---\ntitle: Test}, output)
    assert_match(%r{This is the content\.}, output)
  end

  def test_write_directus_file_creates_file_with_expected_content
    item = {
      "slug"  => "sample-post",
      "title" => "Sample Post",
      "image" => "imgid",
      "body"  => "Body content.",
    }
    @builder.send(:write_directus_file, item, @collection_dir, "post", "https://cms.example.com")
    file = File.join(@collection_dir, "sample-post.md")
    assert File.exist?(file)
    text = File.read(file)
    assert_match(%r{title: Sample Post}, text)
    assert_match(%r{layout: post}, text)
    assert_match(%r{image: https://cms.example.com/assets/imgid}, text)
    assert_match(%r{Body content\.}, text)
  end

  def test_clean_collection_directory_removes_md_files
    FileUtils.mkdir_p(@collection_dir)
    test_file = File.join(@collection_dir, "test.md")
    File.write(test_file, "test")
    assert File.exist?(test_file)
    @builder.send(:clean_collection_directory, @collection_dir)
    refute File.exist?(test_file)
  end
end
