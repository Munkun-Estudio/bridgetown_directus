# frozen_string_literal: true

module BridgetownDirectus
  # Configuration module for Bridgetown Directus plugin
  class Configuration
    attr_reader :collections

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
      attr_reader :name, :endpoint, :fields, :default_query, :resource_type, :layout
      attr_accessor :translations_enabled, :translatable_fields

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
      end

      # Set the Directus endpoint for this collection
      # @param endpoint [String] The endpoint name in Directus
      # @return [void]
      attr_accessor :endpoint

      # Set the fields mapping for this collection
      # @param fields [Hash] A hash mapping Bridgetown field names to Directus field names
      # @return [void]
      attr_accessor :fields

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

      # Set the default query parameters for this collection
      # @param query [Hash] The default query parameters
      # @return [void]
      attr_accessor :default_query

      # Set the resource type for this collection
      # @param type [Symbol] The resource type (e.g., :posts, :pages, :collections)
      # @return [void]
      attr_accessor :resource_type

      # Set the layout for this collection
      # @param layout [String] The layout name
      # @return [void]
      attr_accessor :layout

      # Enable translations for this collection
      # @param fields [Array<Symbol>] The fields that should be translated
      # @return [void]
      def enable_translations(fields = [])
        @translations_enabled = true
        @translatable_fields = fields
      end
    end
  end
end
