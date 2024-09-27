say_status :directus, "Installing the bridgetown_directus plugin..."

# Prompt the user for Directus API URL and Auth Token
api_url = ask("What's your Directus instance URL?")
auth_token = ask("What's your Directus API auth token? (Leave blank to use ENV['DIRECTUS_AUTH_TOKEN'])")

# Add the bridgetown_directus gem
add_gem "bridgetown_directus"

# Append the API URL and Auth Token to the config/initializers.rb file
append_to_file "config/initializers.rb" do
  <<~RUBY

    init :bridgetown_directus do
      api_url "#{api_url}"
      token "#{auth_token.present? ? auth_token : "<%= ENV['DIRECTUS_AUTH_TOKEN'] %>"}"
    end
  RUBY
end

# Finish with a success message
say_status :directus, "All set! Directus integration is complete. Review your configuration in config/initializers.rb."
say_status :directus, "You can refer to the plugin documentation for more details on how to customize your Directus integration."
