# frozen_string_literal: true

# Example Bridgetown Directus plugin initializer for v2+
#
# All Directus configuration is now handled here, NOT in bridgetown.config.yml.
# Use ENV variables for secrets and API credentials.

require "securerandom"
require "time"

init :bridgetown_directus do |directus|
  # Set API credentials from environment variables
  directus.api_url = ENV["DIRECTUS_API_URL"] || "https://your-directus-instance.com"
  directus.token = ENV["DIRECTUS_API_TOKEN"] || "your-token-here"

  # Example custom collection: materials
  directus.register_collection(:materials) do |c|
    c.endpoint = "imasus_materials"
    c.layout = "material"
    c.field :id, "id"
    c.field :title, "title"
    # To enable translations, uncomment and edit:
    # c.enable_translations([:title, :content])
    # Add more fields as needed
  end

  # Example for posts (if needed)
  # directus.register_collection(:posts) do |c|
  #   c.endpoint = "articles"
  #   c.layout = "post"
  #   c.field :title, "title"
  #   c.field :content, "body"
  # end
end
