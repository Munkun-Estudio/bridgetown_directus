# frozen_string_literal: true

module BridgetownDirectus
  class Builder < Bridgetown::Builder
    def build
      return if site.ssr?

      Utils.log_directus "Connecting to Directus API..."
      posts_data = fetch_posts

      Utils.log_directus "Fetched #{posts_data.size} posts from Directus."

      create_documents(posts_data)
    end

    private

    def fetch_posts
      api_client = BridgetownDirectus::APIClient.new(site)
      api_client.fetch_posts
    end

    def create_documents(posts_data)
      languages = site.config.bridgetown_directus.languages || []

      languages.each do |language|
        Utils.log_directus "Processing posts for language: #{language}"

        # Filter posts for the current language
        language_posts = posts_data.select { |post| post["language"] == language }

        language_posts.each_with_index do |post, index|
          # Fallback to slugify if no slug is provided
          slug = post["slug"] || Bridgetown::Utils.slugify(post["title"])
          date = post["date"] || Time.now.iso8601

          # Construct the image URL if the image ID is present
          image = post["image"]
          image = image ? "#{site.config.bridgetown_directus.api_url}/assets/#{image}" : nil

          begin
            add_resource :posts, "#{language}/#{slug}.md" do
              layout "post"
              title post["title"]
              content post["body"] # Make sure content is directly from post["body"]
              date date
              category post["category"]
              excerpt post["excerpt"]
              image image
              lang language
            end
          rescue => e
            Utils.log_directus "Error processing post at index #{index} for language #{language}: #{e.message}"
            raise e
          end
        end

        Utils.log_directus "Finished generating #{language_posts.size} posts for language: #{language}."
      end
    end
  end
end

