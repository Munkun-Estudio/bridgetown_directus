# Bridgetown Directus Plugin

[![Gem Version](https://badge.fury.io/rb/bridgetown_directus.svg)](https://badge.fury.io/rb/bridgetown_directus)

This Bridgetown plugin integrates with [Directus](https://directus.io/), which is among other things a [headless CMS](https://en.wikipedia.org/wiki/Headless_content_management_system). The plugin allows Bridgetown to pull content from a Directus API during the build process and generate static content in your site. It supports both single-language and multilingual content through Directus translations.

## Features

- Fetch content from **multiple Directus collections** during the build process
- Support for **flexible field mapping** with custom converters
- Support for **multilingual content** through Directus translations
- Advanced **filtering, sorting, and pagination** options
- Support for different **resource types** (posts, pages, collections, data)

## Installation

Before installing the plugin make sure you have an [Auth Token](https://docs.directus.io/reference/authentication.html#access-tokens) in your Directus instance.

### Recommended Installation (Bridgetown Automation)

1. Run the plugin's automation setup:

   ```bash
   bin/bridgetown apply https://github.com/munkun-estudio/bridgetown_directus
   ```

2. The setup will guide you through:
   - Providing the Directus API URL and Auth Token
   - Configuring your collections and field mappings
   - Enabling/disabling translations support
   - Configuring translatable fields (if translations enabled)

### Manual Installation

1. Add the gem to your Gemfile:

   ```ruby
   bundle add "bridgetown_directus"
   ```

2. Run bundle install to install the gem.
3. Add the plugin configuration to your config/initializers.rb file (see Configuration section below).

## Configuration

### Basic Configuration

The plugin now uses a more flexible configuration approach that allows you to map multiple collections with custom field mappings:

```ruby
# config/initializers.rb
init :"bridgetown_directus" do |directus|
  # Set API credentials (these can also come from environment variables)
  directus.api_url = ENV["DIRECTUS_API_URL"] || "https://your-directus-instance.com"
  directus.token = ENV["DIRECTUS_API_TOKEN"] || "your-token"
  
  # Configure collections
  directus.register_collection(:posts) do |c|
    c.endpoint = "articles"  # The Directus collection name
    c.resource_type = :posts # The Bridgetown resource type
    c.layout = "post"        # The layout to use for these resources
    
    # Define field mappings with optional converters
    c.field :title, "title"
    c.field :content, "body"
    c.field :date, "published_at" do |value|
      value ? Time.parse(value).iso8601 : Time.now.iso8601
    end
    c.field :slug, "slug" do |value|
      value || "post-#{SecureRandom.hex(4)}"
    end
    
    # Set default query parameters
    c.default_query = { 
      filter: { status: { _eq: "published" } },
      sort: "-published_at"
    }
    
    # Enable translations for specific fields
    c.enable_translations([:title, :content, :excerpt, :slug])
  end
  
  # You can register multiple collections
  directus.register_collection(:projects) do |c|
    # Configuration for projects collection
    # ...
  end
end
```

### Field Mapping Options

The plugin provides a flexible way to map Directus fields to Bridgetown resource attributes:

```ruby
# Simple field mapping
c.field :title, "title"

# Field mapping with a converter
c.field :date, "published_at" do |value|
  value ? Time.parse(value).iso8601 : Time.now.iso8601
end

# Field mapping with default value
c.field :category, "category" do |value|
  value || "Uncategorized"
end

# Field mapping with transformation
c.field :image, "featured_image" do |value|
  value ? "#{config.directus.api_url}/assets/#{value}" : nil
end
```

### Translations Configuration

To enable multilingual support:

```ruby
# Enable translations for specific fields
c.enable_translations([:title, :content, :excerpt, :slug])
```

Make sure your Bridgetown site has the available locales configured:

```yaml
# bridgetown.config.yml
available_locales: [en, es, fr]
default_locale: en
```

### Advanced Querying

You can specify default query parameters for each collection:

```ruby
c.default_query = { 
  filter: { 
    status: { _eq: "published" },
    category: { _in: ["news", "blog"] }
  },
  sort: "-published_at",
  limit: 10
}
```

## Usage

Once the plugin is installed and configured, it will fetch content from your Directus collections during each build. These items will be generated as in-memory resources, meaning they are not written to disk but are treated as normal resources by Bridgetown.

### Directus Setup

#### Collection Setup

Create collections in your Directus instance with the fields you need. Make sure to:

- Set up appropriate permissions for the API token you're using
- Configure status fields if you want to filter by publication status
- Set up translations if you need multilingual support

#### Image Permissions

If your content contains images, ensure that the **directus_files** collection has the appropriate permissions for public access:

1. In Directus, navigate to **Settings** > **Roles & Permissions**
2. Select the **Public** role (or create a custom role if needed)
3. Under the **Collections** tab, locate the **directus_files** collection
4. Set the **read** permission to **enabled** so that the images can be accessed publicly

## Examples

### Multiple Collections Example

```ruby
# config/initializers.rb
init :"bridgetown_directus" do |directus|
  # Blog posts collection
  directus.register_collection(:posts) do |c|
    c.endpoint = "articles"
    c.resource_type = :posts
    c.layout = "post"
    
    c.field :title, "title"
    c.field :content, "body"
    c.field :date, "published_at"
    c.field :slug, "slug"
    
    c.default_query = { filter: { status: { _eq: "published" } } }
  end
  
  # Projects collection
  directus.register_collection(:projects) do |c|
    c.endpoint = "projects"
    c.resource_type = :collections
    c.layout = "project"
    
    c.field :title, "name"
    c.field :content, "description"
    c.field :client, "client"
    c.field :year, "year"
    
    c.default_query = { sort: "year.desc" }
  end
  
  # Team members collection
  directus.register_collection(:team) do |c|
    c.endpoint = "team_members"
    c.resource_type = :data
    
    c.field :name, "full_name"
    c.field :position, "job_title"
    c.field :bio, "biography"
    
    c.default_query = { filter: { active: { _eq: true } } }
  end
end
```

## TODO List

Here are features that are planned for future versions of the plugin:

- [ ] Relationship Resolution: Add support for resolving relationships between collections
- [ ] Real-time Data: Add support for real-time updates via WebSockets
- [ ] Asset Management: Add functionality to download and manage images and other assets
- [ ] Caching & Incremental Builds: Implement caching to improve build performance
- [ ] Schema Introspection: Add optional schema introspection to validate mappings

## Contributing

We welcome contributions! To contribute:

1. Fork the repository
2. Create a new branch (`git checkout -b feature-branch`)
3. Make your changes
4. Run the tests (`bundle exec rake test`)
5. Push to the branch (`git push origin feature-branch`)
6. Open a Pull Request
