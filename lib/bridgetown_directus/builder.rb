# frozen_string_literal: true

require "yaml"

module BridgetownDirectus
  class Builder < Bridgetown::Builder
    def build
      config = site.config.bridgetown_directus
      return if site.ssr?

      config.collections.each_value do |collection_config|
        next unless [:posts, :pages, :custom_collection].include?(collection_config.resource_type)

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

    # Determine the output directory for the given collection name
    def collection_directory(collection_name)
      case collection_name.to_s
      when "posts"
        File.join(site.source, "_posts")
      when "pages"
        File.join(site.source, "_pages")
      else
        File.join(site.source, "_#{collection_name}")
      end
    end

    # Write a Directus item as a Markdown file in the correct Bridgetown collection directory
    def write_directus_file(item, collection_dir, layout = nil, api_url = nil)
      require "fileutils"
      FileUtils.mkdir_p(collection_dir)
      slug = item["slug"] || item["id"].to_s
      filename = build_filename(collection_dir, slug)
      item = transform_item_fields(item, api_url, layout)
      item["directus_generated"] = true # Add flag to front matter
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

    # Remove only plugin-generated Markdown files in the target directory before writing new ones
    def clean_collection_directory(collection_dir)
      require "yaml"
      Dir.glob(File.join(collection_dir, "*.md")).each do |file|
        fm = File.read(file)[%r{\A---.*?---}m]
        File.delete(file) if fm && YAML.safe_load(fm)["directus_generated"]
      rescue StandardError => e
        warn "[BridgetownDirectus] Could not check/delete #{file}: #{e.message}"
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
      collection_dir = collection_directory(collection_config.name)
      clean_collection_directory(collection_dir)
      api_url = site.config.bridgetown_directus.api_url
      sanitized_response = sanitize_keys(response)
      sanitized_response.each do |item|
        write_directus_file(item, collection_dir, collection_config.layout, api_url)
      end
    end

    # Recursively sanitize keys to avoid illegal instance variable names (Ruby 3.4+)
    def sanitize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), h|
          safe_key = if %r{^\d}.match?(k.to_s)
                       "n_#{k}"
                     else
                       k
                     end
          h[safe_key] = sanitize_keys(v)
        end
      when Array
        obj.map { |v| sanitize_keys(v) }
      else
        obj
      end
    end

    # Recursively log all keys to find problematic ones
    def log_all_keys(obj, path = "")
      case obj
      when Hash
        obj.each do |k, v|
          # puts "[BridgetownDirectus DEBUG] Key at #{path}: #{k.inspect}" if %r{^\d}.match?(k.to_s)
          log_all_keys(v, "#{path}/#{k}")
        end
      when Array
        obj.each_with_index do |v, idx|
          log_all_keys(v, "#{path}[#{idx}]")
        end
      end
    end
  end
end
