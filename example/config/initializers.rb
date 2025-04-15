# frozen_string_literal: true

# Example Bridgetown Directus plugin initializer for v2+
#
# All Directus configuration is now handled here, NOT in bridgetown.config.yml.
# Use ENV variables for secrets and API credentials.

require "securerandom"
require "time"

init :bridgetown_directus do |directus| # rubocop:disable Metrics/BlockLength
  # Set API credentials from environment variables
  directus.api_url = ENV["DIRECTUS_API_URL"] || "https://your-directus-instance.com"
  directus.token = ENV["DIRECTUS_API_TOKEN"] || "your-token-here"

  # Blog posts collection example
  directus.register_collection(:posts) do |c|
    c.endpoint = "articles"
    c.resource_type = :posts
    c.layout = "post"

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
      value ? "#{ENV["DIRECTUS_API_URL"] || "https://your-directus-instance.com"}/assets/#{value}" : nil # rubocop:disable Layout/LineLength
    end

    # Set default query parameters
    c.default_query = {
      filter: { status: { _eq: "published" } },
      sort: "-published_at",
    }

    # Enable translations for specific fields
    c.enable_translations([:title, :content, :excerpt, :slug])
  end

  # Team members collection example
  directus.register_collection(:team) do |c|
    c.endpoint = "team_members"
    c.resource_type = :team
    c.layout = "team_member"

    c.field :name, "full_name"
    c.field :position, "job_title"
    c.field :bio, "biography"
    c.field :photo, "photo" do |value|
      value ? "#{ENV["DIRECTUS_API_URL"] || "https://your-directus-instance.com"}/assets/#{value}" : nil # rubocop:disable Layout/LineLength
    end
    c.field :social_links, "social_links"

    c.default_query = {
      filter: { active: { _eq: true } },
      sort: "sort_order",
    }
  end
end
