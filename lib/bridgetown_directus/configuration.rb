# frozen_string_literal: true

module BridgetownDirectus
  # Configuration module for Bridgetown Directus plugin
  class Configuration
    attr_reader :collections
    attr_accessor :api_url, :token

    def initialize
      @collections = {}
    end

    # Register a new collection with the given name
    # @param name [Symbol] The name of the collection
    # @param block [Proc] Configuration block for the collection
    # @return [CollectionConfig] The collection configuration
    def register_collection(name, &block)
      collection = CollectionConfig.new(name)
      collection.instance_eval(&block) if block_given?
      @collections[name] = collection
      collection
    end

    # Find a collection by name
    # @param name [Symbol] The name of the collection
    # @return [CollectionConfig, nil] The collection configuration or nil if not found
    def find_collection(name)
      @collections[name]
    end

    # Collection configuration class
    class CollectionConfig
      attr_reader :name

      # Initialize a new collection configuration
      # @param name [Symbol] The name of the collection
      def initialize(name)
        @name = name
        @fields = {}
        @default_query = {}
        @resource_type = :posts
        @layout = "post"
        @translations_enabled = false
        @translatable_fields = []
        @endpoint = nil
        @singleton = false
        @m2m_flattenings = []
      end

      # Set up accessors for collection configuration properties
      attr_accessor :endpoint, :fields, :default_query, :resource_type, :layout,
                    :translations_enabled, :translatable_fields, :singleton
      attr_reader :m2m_flattenings

      # Register a many-to-many junction to flatten after fetching.
      # Directus returns M2M data wrapped in junction objects like:
      #   [{"raus_stats_id": {"id": 1, "value": "8+"}}]
      # This unwraps them to:
      #   [{"id": 1, "value": "8+"}]
      #
      # @param path [String] Dot-separated path to the M2M field (e.g. "sections.stats")
      # @param key [String] The junction key containing the actual related item
      # @return [void]
      def flatten_m2m(path, key:)
        @m2m_flattenings << { path: path, key: key }
      end

      # Check if this collection is a data-only collection
      # @return [Boolean]
      def data?
        @resource_type == :data
      end

      # Define a field mapping with optional converter
      # @param bridgetown_field [Symbol] The field name in Bridgetown
      # @param directus_field [String, Symbol] The field name in Directus
      # @param converter [Proc, nil] Optional converter to transform the field value
      # @return [void]
      def field(bridgetown_field, directus_field, &converter)
        @fields[bridgetown_field] = {
          directus_field: directus_field.to_s,
          converter: converter,
        }
      end

      # Enable translations for this collection
      # @param fields [Array<Symbol>] The fields that should be translated
      # @return [void]
      def enable_translations(fields = [])
        @translations_enabled = true
        @translatable_fields = fields
      end

      # Generate the resource path for a given item
      # @param item [Hash] The data item from Directus
      # @return [String] The resource path
      def path(item)
        # Default: /:resource_type/:slug/index.html
        slug = item["slug"] || item[:slug] || item["id"] || item[:id]
        "/#{resource_type}/#{slug}/index.html"
      end
    end
  end
end
