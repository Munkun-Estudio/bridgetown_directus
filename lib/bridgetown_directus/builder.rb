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
      posts_array = posts_data["data"]

      posts_array.each_with_index do |post, index|
        next unless post["status"] == "published"

        slug = Bridgetown::Utils.slugify(post["slug"] || post["title"])
        date = post["date"] || Time.now.iso8601

        Utils.log_directus "Generating post #{post['title']}"

        add_resource :posts, "#{slug}.md" do
          title post["title"]
          date date
          content post["body"]
          layout "post"
        end
      end

      Utils.log_directus "Finished generating #{posts_array.size} posts."
    end
  end
end
