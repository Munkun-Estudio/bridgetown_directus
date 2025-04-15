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
      end

      # Set up accessors for collection configuration properties
      attr_accessor :endpoint, :fields, :default_query, :resource_type, :layout,
                    :translations_enabled, :translatable_fields

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
