say_status :directus, "Installing the bridgetown_directus plugin..."

# Prompt the user for Directus API URL and Auth Token
api_url = ask("What's your Directus instance URL? (Example: https://your-instance.example.com)")
auth_token = ask("What's your Directus API auth token? (Leave blank to use ENV['DIRECTUS_AUTH_TOKEN'])")
collection = ask("What's the name of the collection (Directus Model)? (Example: posts)")

# Ask if translations should be enabled with a default of 'n'
translations_enabled_input = ask("Do you want to enable translations? (y/n) default:", :yellow, default: "n")
translations_enabled = translations_enabled_input.strip.downcase.start_with?("y")

# Prepare the translations YAML block based on the user’s response
translations_yaml = if translations_enabled
  translatable_fields_input = ask("List the translatable fields separated by commas (e.g., title, excerpt, content)")
  translatable_fields = translatable_fields_input.split(',').map(&:strip)

  "  translations:\n    enabled: true\n    fields:\n#{translatable_fields.map { |field| "      - #{field}" }.join("\n")}"
else
  "  translations:\n    enabled: false"
end

# Add the bridgetown_directus gem
add_gem "bridgetown_directus"

# Add Directus configuration to config/initializers.rb
add_initializer :bridgetown_directus do
  <<~RUBY
  do
    api_url "#{api_url}"
    token "#{auth_token.present? ? auth_token : "<%= ENV['DIRECTUS_AUTH_TOKEN'] %>"}"
    collection config.directus["collection"]
    mappings config.directus["mappings"]
  end
  RUBY
end

# Append the configuration to bridgetown.config.yml
append_to_file "bridgetown.config.yml" do
  <<~YAML

directus:
  collection: "#{collection}"
  mappings:
    title: "title"           # Required field
    content: "body"          # Required field
    slug: "slug"             # Optional, will be auto-generated if not provided
    date: "date"             # Optional, defaults to the current date/time if not provided
    category: "category"     # Optional
    excerpt: "excerpt"       # Optional, defaults to content excerpt if not provided
    image: "image"           # Optional, URL for the image associated with the post
#{translations_yaml}
  YAML
end

say_status :success, "Bridgetown Directus plugin has been installed!", :green
say_status :info, "Add your posts to Directus and they will be automatically imported when you build your site.", :yellow
if translations_enabled
  say_status :info, "Translations are enabled. Make sure your Directus collection has translations configured.", :yellow
end
say_status :directus, "Check config/initializers.rb for your Directus setup and config.bridgetown.yml to adjust fields mappings if necessary."
say_status :directus, "For usage help visit:"
say_status :directus, "https://github.com/Munkun-Estudio/bridgetown_directus/blob/main/README.md"