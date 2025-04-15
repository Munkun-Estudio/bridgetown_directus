# frozen_string_literal: true

require "yaml"

module BridgetownDirectus
  class Builder < Bridgetown::Builder
    def build
      config = site.config.bridgetown_directus
      return if site.ssr?

      config.collections.each_value do |collection_config|
        process_collection(
          client: Client.new(
            api_url: config.api_url,
            token: config.token
          ),
          collection_config: collection_config
        )
      end
    end

    private

    # Determine the output directory for the given resource type
    def collection_directory(resource_type)
      case resource_type.to_s
      when "posts"
        File.join(site.source, "_posts")
      when "pages"
        File.join(site.source, "_pages")
      else
        File.join(site.source, "_#{resource_type}")
      end
    end

    # Write a Directus item as a Markdown file in the correct Bridgetown collection directory
    def write_directus_file(item, collection_dir, layout = nil, api_url = nil)
      require "fileutils"
      FileUtils.mkdir_p(collection_dir)
      slug = item["slug"] || item["id"].to_s
      filename = build_filename(collection_dir, slug)
      item = transform_item_fields(item, api_url, layout)
      content = item.delete("body") || ""
      front_matter = generate_front_matter(item)
      write_markdown_file(filename, front_matter, content)
    end

    def build_filename(collection_dir, slug)
      File.join(collection_dir, "#{slug}.md")
    end

    def transform_item_fields(item, api_url, layout)
      item = item.dup
      if item["image"] && api_url && !item["image"].to_s.start_with?("http://", "https://")
        item["image"] = File.join(api_url, "assets", item["image"])
      end
      item["layout"] = layout if layout
      item
    end

    def generate_front_matter(item)
      yaml = item.to_yaml
      yaml.sub(%r{^---\s*\n}, "") # Remove leading --- if present
    end

    def write_markdown_file(filename, front_matter, content)
      File.write(filename, "---\n#{front_matter}---\n\n#{content}")
    end

    # Remove all Markdown files in the target directory before writing new ones
    def clean_collection_directory(collection_dir)
      require "fileutils"
      Dir.glob(File.join(collection_dir, "*.md")).each do |file|
        FileUtils.rm_f(file)
      end
    end

    def process_collection(client:, collection_config:)
      endpoint = collection_config.endpoint || collection_config.name.to_s
      begin
        response = client.fetch_collection(endpoint, collection_config.default_query)
      rescue StandardError => e
        warn "Error fetching collection '#{endpoint}': #{e.message}"
        return
      end
      collection_dir = collection_directory(collection_config.resource_type)
      clean_collection_directory(collection_dir)
      api_url = site.config.bridgetown_directus.api_url
      response.each do |item|
        write_directus_file(item, collection_dir, collection_config.layout, api_url)
      end
    end
  end
end
