say_status :directus, "Installing the bridgetown_directus plugin..."

# Prompt the user for Directus API URL and Auth Token
api_url = ask("What's your Directus instance URL? (Example: https://your-instance.example.com)")
auth_token = ask("What's your Directus API auth token? (Leave blank to use ENV['DIRECTUS_AUTH_TOKEN'])")
collection = ask("What's the name of the collection? (Example: posts")

# Prompt the user for multilanguage support
enable_multilanguage = yes?("Do you want to enable multilanguage support? (yes/no)")
languages = enable_multilanguage ? ask("Which languages do you want to support? (Comma-separated, e.g., en,es,fr)") : ""

# Add the bridgetown_directus gem
add_gem "bridgetown_directus"

# Add Directus configuration to config/initializers.rb using add_initializer method
add_initializer :"bridgetown_directus" do
  <<~RUBY
    do
      api_url "#{api_url}"
      token "#{auth_token.present? ? auth_token : "<%= ENV['DIRECTUS_AUTH_TOKEN'] %>"}"
      collection "#{collection}"

      # Multilanguage Support
      multilanguage "#{enable_multilanguage}"
      languages "#{languages}"

      # Field Mappings (Ensure your Directus collection has these fields)
      mappings do
        title "title"           # Required field
        content "content"       # Required field
        slug "slug"             # Optional, will be auto-generated if not provided
        date "date"             # Optional, defaults to the current date/time if not provided
        category "category"     # Optional
        excerpt "excerpt"       # Optional, defaults to content excerpt if not provided
        image "image"           # Optional, URL for the image associated with the post
      end
    end
  RUBY
end
# Success message
say_status :directus, "Directus integration is complete! Please make sure your Directus collection contains the required fields as specified in the initializer."
say_status :directus, "Check config/initializers.rb for your Directus setup and adjust mappings if necessary."
say_status :directus, "For usage help visit:"
say_status :directus, "https://github.com/Munkun-Estudio/bridgetown_directus/blob/main/README.md"

