# frozen_string_literal: true

module BridgetownDirectus
  # Data mapper for transforming Directus data into Bridgetown resources
  class DataMapper
    class << self
      # Map Directus data to Bridgetown format based on collection configuration
      # @param collection_config [CollectionConfig] The collection configuration
      # @param data [Hash] The Directus data
      # @return [Hash] The mapped data
      def map(collection_config, data)
        mapped_data = {}

        collection_config.fields.each do |bridgetown_field, field_config|
          if field_config.is_a?(Hash)
            directus_field = field_config[:directus_field]
            converter = field_config[:converter]

            value = extract_value(data, directus_field)

            # Apply converter if provided
            value = converter.call(value) if converter.respond_to?(:call)

            mapped_data[bridgetown_field] = value
          else
            # Support for simple string mapping for backward compatibility
            directus_field = field_config.to_s
            mapped_data[bridgetown_field] = extract_value(data, directus_field)
          end
        end

        mapped_data
      end

      # Map translated fields from Directus data
      # @param collection_config [CollectionConfig] The collection configuration
      # @param data [Hash] The Directus data
      # @param locale [Symbol] The locale to map
      # @return [Hash] The mapped data with translations
      def map_translations(collection_config, data, locale)
        # First map the base data
        mapped_data = map(collection_config, data)

        # If translations are enabled and the data has translations
        return mapped_data unless collection_config.translations_enabled && data["translations"]

        # Find the translation for the requested locale
        translation = find_translation_for_locale(data["translations"], locale)

        # Apply translations if found
        if translation
          apply_translations(collection_config, translation, mapped_data)
          mapped_data[:locale] = locale
        end

        mapped_data
      end

      # Resolve relationships in the data
      # @param client [Client] The Directus client
      # @param collection_config [CollectionConfig] The collection configuration
      # @param data [Hash] The mapped data
      # @param relationships [Hash] Relationship configuration
      # @return [Hash] The data with resolved relationships
      def resolve_relationships(client, collection_config, data, relationships)
        return data unless relationships

        resolved_data = data.dup

        relationships.each do |field, relationship_config|
          relation_id = data[field]
          next unless relation_id

          related_collection = relationship_config[:collection]
          related_fields = relationship_config[:fields] || "*"

          # Fetch the related item
          related_item = client.fetch_item(
            related_collection,
            relation_id,
            { fields: related_fields }
          )

          # Add the related data to the resolved data
          if related_item && related_item["data"]
            resolved_data["#{field}_data"] = related_item["data"]
          end
        end

        resolved_data
      end

      private

      # Find translation for a specific locale
      # @param translations [Array] Array of translation objects
      # @param locale [Symbol] The locale to find
      # @return [Hash, nil] The translation for the locale or nil if not found
      def find_translation_for_locale(translations, locale)
        translations.find do |t|
          lang_code = t["languages_code"].to_s.split("-").first.downcase
          lang_code == locale.to_s
        end
      end

      # Apply translations to mapped data
      # @param collection_config [CollectionConfig] The collection configuration
      # @param translation [Hash] The translation data
      # @param mapped_data [Hash] The mapped data to update
      # @return [void]
      def apply_translations(collection_config, translation, mapped_data)
        collection_config.translatable_fields.each do |field|
          # Get the Directus field name for this Bridgetown field
          field_config = collection_config.fields[field]

          directus_field = if field_config.nil?
                             field.to_s
                           elsif field_config.is_a?(Hash)
                             field_config[:directus_field]
                           else
                             field_config.to_s
                           end

          directus_field = field.to_s if directus_field.to_s.empty?

          # Check if the translation has this field
          next unless translation[directus_field]

          value = translation[directus_field]

          # Apply converter if provided
          if field_config.is_a?(Hash) && field_config[:converter].respond_to?(:call)
            value = field_config[:converter].call(value)
          end

          mapped_data[field] = value
        end
      end

      # Extract a value from nested data using dot notation
      # @param data [Hash] The data to extract from
      # @param field [String] The field path (e.g., "user.profile.name")
      # @return [Object] The extracted value
      def extract_value(data, field)
        return nil unless data

        keys = field.to_s.split(".")
        value = data

        keys.each do |key|
          return nil unless value.is_a?(Hash) && value.key?(key)

          value = value[key]
        end

        value
      end
    end
  end
end
