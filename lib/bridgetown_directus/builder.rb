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
      # Ensure posts_data contains a "data" key and it is an array
      if posts_data.is_a?(Hash) && posts_data.key?("data") && posts_data["data"].is_a?(Array)
        posts_array = posts_data["data"]
      elsif posts_data.is_a?(Array)
        posts_array = posts_data
      else
        raise "Unexpected structure of posts_data: #{posts_data.inspect}"
      end

      created_posts = 0
      posts_array.each do |post|
        if translations_enabled?
          created_posts += create_translated_posts(post)
        else
          created_posts += create_single_post(post)
        end
      end

      Utils.log_directus "Finished generating #{created_posts} posts."
    end

    def translations_enabled?
      site.config.dig("directus", "translations", "enabled") == true
    end

    def create_single_post(post)
      slug = post["slug"] || Bridgetown::Utils.slugify(post["title"])
      api_url = site.config.dig("directus", "api_url")

      begin
        add_resource :posts, "#{slug}.md" do
          layout "post"
          title post["title"]
          content post["body"]
          date post["date"] || Time.now.iso8601
          category post["category"]
          excerpt post["excerpt"]
          image post["image"] ? "#{api_url}/assets/#{post['image']}" : nil
        end
        1
      rescue => e
        Utils.log_directus "Error creating post #{slug}: #{e.message}"
        0
      end
    end

    def create_translated_posts(post)
      posts_created = 0
      translations = post["translations"] || []

      translations.each do |translation|
        lang_code = translation["languages_code"].split("-").first.downcase
        bridgetown_locale = lang_code.to_sym
        
        next unless site.config["available_locales"].include?(bridgetown_locale)

        slug = translation["slug"] || Bridgetown::Utils.slugify(translation["title"])
        api_url = site.config.dig("directus", "api_url")

        begin
          add_resource :posts, "#{slug}.md" do
            layout "post"
            title translation["title"]
            content translation["body"]
            date post["date"] || Time.now.iso8601
            category post["category"]
            excerpt translation["excerpt"]
            image post["image"] ? "#{api_url}/assets/#{post['image']}" : nil
            locale bridgetown_locale
            translations translations
          end

          posts_created += 1
        rescue => e
          Utils.log_directus "Error creating post #{slug} for locale #{bridgetown_locale}: #{e.message}"
        end
      end

      posts_created
    end
  end
end
