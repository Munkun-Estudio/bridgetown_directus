# frozen_string_literal: true

require "date"
require "fileutils"
require "yaml"

module BridgetownDirectus
  class Builder < Bridgetown::Builder
    def build
      config = site.config.bridgetown_directus
      return if site.ssr?
      return unless config&.api_url && config&.token

      client = Client.new(api_url: config.api_url, token: config.token, ssl_verify: config.ssl_verify)

      config.collections.each_value do |collection_config|
        if collection_config.data?
          process_data_collection(client: client, collection_config: collection_config)
        elsif [:posts, :pages, :custom_collection].include?(collection_config.resource_type)
          process_collection(client: client, collection_config: collection_config)
        end
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

    def build_directus_payload(item, collection_dir, collection_config, api_url = nil)
      mapped_item = apply_data_mapping(item, collection_config)
      slug = normalize_slug(mapped_item)
      mapped_item["slug"] = slug
      filename = build_filename(collection_dir, collection_config, mapped_item, slug)
      mapped_item = transform_item_fields(mapped_item, api_url, collection_config.layout)
      mapped_item["directus_generated"] = true # Add flag to front matter
      content = mapped_item.delete("body") || ""
      front_matter = generate_front_matter(mapped_item)
      payload = render_markdown(front_matter, content)
      [filename, payload]
    end

    def build_filename(collection_dir, collection_config, item, slug)
      if collection_config.resource_type == :posts || collection_config.name.to_s == "posts"
        post_date = extract_post_date(item)
        if post_date
          return File.join(collection_dir, "#{post_date.strftime("%Y-%m-%d")}-#{slug}.md")
        end
      end

      File.join(collection_dir, "#{slug}.md")
    end

    def normalize_slug(item)
      slug = item["slug"] || item[:slug]
      slug = slug.to_s.strip
      return slug unless slug.empty?

      title = item["title"] || item[:title]
      if title && defined?(Bridgetown::Utils) && Bridgetown::Utils.respond_to?(:slugify)
        slug = Bridgetown::Utils.slugify(title.to_s)
      else
        slug = title.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      end

      slug = slug.strip
      return slug unless slug.empty?

      id = item["id"] || item[:id]
      id.to_s
    end

    def apply_data_mapping(item, collection_config)
      mapped_item = item.dup
      return mapped_item unless collection_config.fields.any? || collection_config.translations_enabled

      mapped_fields = if collection_config.translations_enabled
                        DataMapper.map_translations(collection_config, item, resolve_locale)
                      else
                        DataMapper.map(collection_config, item)
                      end

      mapped_item.merge!(mapped_fields)
      mapped_item
    end

    def resolve_locale
      return site.locale if site.respond_to?(:locale) && site.locale

      config_locale = site.config["locale"] || site.config[:locale]
      return config_locale.to_sym if config_locale

      :en
    end

    def extract_post_date(item)
      raw = item["date"] || item[:date] || item["published_at"] || item[:published_at] || item["date_created"]
      item["date"] ||= item["published_at"] if item["published_at"] && !item["date"]
      return nil unless raw

      return raw.to_date if raw.respond_to?(:to_date)

      Date.parse(raw.to_s)
    rescue ArgumentError
      nil
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

    def render_markdown(front_matter, content)
      "---\n#{front_matter}---\n\n#{content}"
    end

    def write_markdown_file(filename, payload)
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, payload)
    end

    def file_unchanged?(filename, payload)
      return false unless File.exist?(filename)

      File.read(filename) == payload
    rescue StandardError
      false
    end

    # Remove only plugin-generated Markdown files in the target directory before writing new ones
    def clean_collection_directory(collection_dir, keep_files: [])
      keep_set = keep_files.map { |file| File.expand_path(file) }.to_h { |file| [file, true] }

      deleted = 0
      Dir.glob(File.join(collection_dir, "*.md")).each do |file|
        next if keep_set[File.expand_path(file)]

        fm = File.read(file)[%r{\A---.*?---}m]
        if fm && YAML.safe_load(fm, permitted_classes: [Date, Time, DateTime])["directus_generated"]
          File.delete(file)
          deleted += 1
        end
      rescue StandardError => e
        warn "[BridgetownDirectus] Could not check/delete #{file}: #{e.message}"
      end

      deleted
    end

    # Fetch a data-only collection and inject into site.data (no file generation)
    def process_data_collection(client:, collection_config:)
      endpoint = collection_config.endpoint || collection_config.name.to_s
      begin
        response = client.fetch_collection(endpoint, collection_config.default_query)
      rescue StandardError => e
        warn "Error fetching data collection '#{endpoint}': #{e.message}"
        return
      end

      process_data_collection_with_data(response, collection_config)
    end

    # Process already-fetched data for a data collection (also used in tests)
    def process_data_collection_with_data(response, collection_config)
      data = sanitize_keys(response)

      if collection_config.singleton
        data = data.is_a?(Array) ? data.first : data
      end

      # Apply M2M flattening if configured
      apply_m2m_flattenings!(data, collection_config)

      site.data[collection_config.name.to_s] = data
      log_directus("Loaded data collection: #{collection_label(collection_config)}#{collection_config.singleton ? ' (singleton)' : " (#{Array(data).size} items)"}")
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
      FileUtils.mkdir_p(collection_dir)
      api_url = site.config.bridgetown_directus.api_url
      sanitized_response = sanitize_keys(response)
      payloads = sanitized_response.to_h do |item|
        build_directus_payload(item, collection_dir, collection_config, api_url)
      end
      log_directus("Generating #{collection_label(collection_config)} (#{payloads.size} items)")
      deleted = clean_collection_directory(collection_dir, keep_files: payloads.keys)
      written = 0
      skipped = 0
      payloads.each do |filename, payload|
        if file_unchanged?(filename, payload)
          skipped += 1
          next
        end

        write_markdown_file(filename, payload)
        written += 1
      end
      log_directus("Updated #{collection_label(collection_config)}: wrote #{written}, skipped #{skipped}, deleted #{deleted}")
    end

    # Apply M2M junction flattening to fetched data.
    # Walks the configured dot-paths and unwraps junction objects.
    def apply_m2m_flattenings!(data, collection_config)
      return if collection_config.m2m_flattenings.empty?

      items = data.is_a?(Array) ? data : [data].compact
      collection_config.m2m_flattenings.each do |flattening|
        path_parts = flattening[:path].split(".")
        junction_key = flattening[:key]
        items.each { |item| flatten_at_path!(item, path_parts, junction_key) }
      end
    end

    # Recursively walk a dot-path and flatten the M2M array at the leaf.
    def flatten_at_path!(obj, path_parts, junction_key)
      return unless obj.is_a?(Hash)

      key = path_parts.first
      remaining = path_parts[1..]

      if remaining.empty?
        # We're at the leaf — flatten the junction array
        return unless obj[key].is_a?(Array)

        obj[key] = obj[key].filter_map { |junction| junction[junction_key] if junction.is_a?(Hash) }
      else
        # Intermediate path — recurse into nested object(s)
        target = obj[key]
        if target.is_a?(Array)
          target.each { |nested| flatten_at_path!(nested, remaining, junction_key) }
        elsif target.is_a?(Hash)
          flatten_at_path!(target, remaining, junction_key)
        end
      end
    end

    def log_directus(message)
      return unless directus_logging_enabled?

      Utils.log_directus(message)
    end

    def directus_logging_enabled?
      flag = ENV["BRIDGETOWN_DIRECTUS_LOG"]
      flag && !flag.to_s.strip.empty? && flag.to_s != "0"
    end

    def collection_label(collection_config)
      collection_config.name.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
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
