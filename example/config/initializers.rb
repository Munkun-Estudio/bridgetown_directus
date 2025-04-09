# Example initializers.rb file for the enhanced Directus plugin

# Initialize the Bridgetown Directus plugin with a more flexible configuration
init :bridgetown_directus do |directus|
  # Set API credentials (these can also come from environment variables)
  directus.api_url = config.directus.api_url
  directus.token = config.directus.token

  # Configure collections

  # Blog posts collection
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
    c.field :excerpt, "excerpt" do |value|
      value || ""
    end
    c.field :category, "category"
    c.field :image, "featured_image" do |value|
      value ? "#{config.directus.api_url}/assets/#{value}" : nil
    end

    # Set default query parameters
    c.default_query = {
      filter: { status: { _eq: "published" } },
      sort: "-published_at",
    }

    # Enable translations for specific fields
    c.enable_translations([:title, :content, :excerpt, :slug])
  end

  # Projects collection
  directus.register_collection(:projects) do |c|
    c.endpoint = "projects"
    c.resource_type = :collections
    c.layout = "project"

    # Define field mappings
    c.field :title, "name"
    c.field :content, "description"
    c.field :client, "client"
    c.field :year, "year"
    c.field :technologies, "technologies"
    c.field :image, "cover_image" do |value|
      value ? "#{config.directus.api_url}/assets/#{value}" : nil
    end
    c.field :gallery, "gallery" do |value|
      # Convert gallery items to full URLs
      if value.is_a?(Array)
        value.map { |img| "#{config.directus.api_url}/assets/#{img}" }
      else
        []
      end
    end

    # Set default query parameters
    c.default_query = {
      filter: { status: { _eq: "published" } },
      sort: "year.desc",
    }
  end

  # Team members collection
  directus.register_collection(:team) do |c|
    c.endpoint = "team_members"
    c.resource_type = :data

    # Define field mappings
    c.field :name, "full_name"
    c.field :position, "job_title"
    c.field :bio, "biography"
    c.field :photo, "photo" do |value|
      value ? "#{config.directus.api_url}/assets/#{value}" : nil
    end
    c.field :social_links, "social_links"

    # Set default query parameters
    c.default_query = {
      filter: { active: { _eq: true } },
      sort: "sort_order",
    }
  end
end
