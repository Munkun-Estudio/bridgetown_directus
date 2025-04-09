module BridgetownDirectus
  class Builder < Bridgetown::Builder
    def build
      return if site.ssr?

      Utils.log_directus "Connecting to Directus API..."
      
      # Get the configuration
      config = site.config.bridgetown_directus
      
      # Create a client
      client = BridgetownDirectus::Client.new(
        api_url: config.api_url,
        token: config.token
      )
      
      # Process each configured collection
      config.collections.each do |name, collection_config|
        process_collection(client, collection_config)
      end
    end

    private

    def process_collection(client, collection_config)
      Utils.log_directus "Processing collection: #{collection_config.name}"
      
      # Fetch the collection data
      endpoint = collection_config.endpoint || collection_config.name.to_s
      
      # Prepare query parameters
      params = collection_config.default_query || {}
      
      # Add fields parameter if not specified
      unless params[:fields]
        # Include translations if enabled
        if collection_config.translations_enabled
          params[:fields] = "*,translations.*"
        else
          params[:fields] = "*"
        end
      end
      
      # Fetch the data
      response = client.fetch_collection(endpoint, params)
      
      # Extract the items from the response
      items = extract_items(response)
      
      Utils.log_directus "Fetched #{items.size} items from collection: #{collection_config.name}"
      
      # Process the items
      process_items(client, collection_config, items)
    end
    
    def extract_items(response)
      if response.is_a?(Hash) && response.key?("data") && response["data"].is_a?(Array)
        response["data"]
      elsif response.is_a?(Array)
        response
      else
        raise "Unexpected structure of response: #{response.inspect}"
      end
    end
    
    def process_items(client, collection_config, items)
      created_items = 0
      
      items.each do |item|
        if collection_config.translations_enabled
          created_items += create_translated_items(client, collection_config, item)
        else
          created_items += create_single_item(client, collection_config, item)
        end
      end
      
      Utils.log_directus "Finished generating #{created_items} items for collection: #{collection_config.name}"
    end
    
    def create_single_item(client, collection_config, item)
      # Map the data using the DataMapper
      mapped_data = BridgetownDirectus::DataMapper.map(collection_config, item)
      
      # Generate a slug if not provided
      slug = mapped_data[:slug] || Bridgetown::Utils.slugify(mapped_data[:title] || "item-#{item['id']}")
      
      # Determine the resource type and file extension
      resource_type = collection_config.resource_type || :posts
      file_ext = resource_type == :posts ? ".md" : ".html"
      
      begin
        # Create the resource
        add_resource resource_type, "#{slug}#{file_ext}" do
          layout collection_config.layout || "post"
          
          # Add all mapped data as front matter
          mapped_data.each do |key, value|
            # Skip content as it will be set separately
            next if key == :content
            
            # Set the front matter
            instance_variable_set("@#{key}", value)
          end
          
          # Set the content
          content mapped_data[:content] || ""
        end
        
        1
      rescue => e
        Utils.log_directus "Error creating item #{slug}: #{e.message}"
        0
      end
    end
    
    def create_translated_items(client, collection_config, item)
      items_created = 0
      
      # Get available locales from the site configuration
      available_locales = site.config["available_locales"] || []
      
      # Process each available locale
      available_locales.each do |locale|
        # Map the data with translations for the specific locale
        mapped_data = BridgetownDirectus::DataMapper.map_translations(collection_config, item, locale)
        
        # Generate a slug if not provided
        slug = mapped_data[:slug] || Bridgetown::Utils.slugify(mapped_data[:title] || "item-#{item['id']}")
        
        # Add locale suffix to the slug if needed
        slug = "#{slug}-#{locale}" unless locale == site.config["default_locale"]
        
        # Determine the resource type and file extension
        resource_type = collection_config.resource_type || :posts
        file_ext = resource_type == :posts ? ".md" : ".html"
        
        begin
          # Create the resource
          add_resource resource_type, "#{slug}#{file_ext}" do
            layout collection_config.layout || "post"
            
            # Add all mapped data as front matter
            mapped_data.each do |key, value|
              # Skip content as it will be set separately
              next if key == :content
              
              # Set the front matter
              instance_variable_set("@#{key}", value)
            end
            
            # Set the content
            content mapped_data[:content] || ""
            
            # Set the locale
            locale locale
          end
          
          items_created += 1
        rescue => e
          Utils.log_directus "Error creating translated item #{slug} for locale #{locale}: #{e.message}"
        end
      end
      
      items_created
    end
  end
end
