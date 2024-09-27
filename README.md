# Bridgetown Directus Plugin

This Bridgetown plugin integrates with the [Directus](https://directus.io/) which is among other things a [headless CMS](https://en.wikipedia.org/wiki/Headless_content_management_system). The plugin allows Bridgetown to pull content from a Directus API during the build process and generate static content in your site. It currently supports fetching published posts, with future plans for more flexibility and features.

## Features

- Fetch **published posts** from Directus during the build process
- Simple setup and configuration

## Installation

Before installing the plugin make sure you have an [Auth Token](https://docs.directus.io/reference/authentication.html#access-tokens) in your Directus instance.

### Recommended Installation (Bridgetown Automation)

1. Run the plugin's automation setup:
   ```bash
   bin/bridgetown apply https://github.com/munkun-estudio/bridgetown_directus
   ```
2.	The setup will guide you to provide the Directus API URL and Auth Token, and configure the plugin automatically.

### Manual Installation

1.	Add the gem to your Gemfile:
```ruby
bundle add "bridgetown_directus"
```
2.	Run bundle install to install the gem.
3.	Add the plugin configuration to your config/initializers.rb file:
```ruby
init :bridgetown_directus do
  api_url "https://your-directus-instance.com"
  token ENV['DIRECTUS_AUTH_TOKEN'] || "your_token"
end
```

## Configuration

To configure the plugin:

1.	You can either use environment variables for the API URL and token:
```bash
export DIRECTUS_API_URL="https://your-directus-instance.com"
export DIRECTUS_AUTH_TOKEN="your-token"
```

2.	Or hard-code the values directly in your initializer:
```ruby
init :bridgetown_directus do
  api_url "https://your-directus-instance.com"
  token "your_token"
end
```
## Usage

Once the plugin is installed and configured, it will fetch posts from your Directus instance during each build. These posts will be generated as in-memory resources, meaning they are not written to disk but are treated as normal posts by Bridgetown.

### Directus Setup

To use the plugin, ensure that you've set up a **posts** collection in your Directus instance with the following fields:

- **title**: The title of the post (Text field)
- **date**: The publish date (Datetime field)
- **body**: The content of the post (Rich Text or Text field)
- **slug**: A unique slug for the post (Text field)
- **status**: The status of the post (Option field, with values like "published", "draft", "archived", etc.)

Make sure the **status** field uses `"published"` for posts that you want to be visible on your site.

#### Image Permissions

If your posts contain images, and you want to display them in your Bridgetown site, you'll need to ensure that the **directus_files** collection has the appropriate permissions for public access.

1. **Public Role Configuration:**
   - In Directus, navigate to **Settings** > **Roles & Permissions**.
   - Select the **Public** role (or create a custom role if needed).
   - Under the **Collections** tab, locate the **directus_files** collection.
   - Set the **read** permission to **enabled** so that the images can be accessed publicly.

2. **Image Uploads and Management:**
   - When users upload images to posts, ensure that the images are associated with the **directus_files** collection.
   - By default, Directus will store image URLs, which the plugin can reference directly. Ensure that the **image** field or URL is added to the **body** field (or wherever applicable).


### Fetching Posts

Posts are fetched from Directus during each build and treated as Bridgetown resources. These resources are available in your site just like regular posts, and you can access them through your templates or layouts.

By default, only posts with a status of "published" are fetched from Directus.

## TODO List

Here are features that are planned for future versions of the plugin:

- [ ]	Support for Additional Content Types: Extend the plugin to handle other Directus collections and custom content types.
- [ ]	Custom Field Mapping via DSL: Implement a DSL for more advanced field mapping.
- [ ]	Asset Handling: Add functionality to download and manage images and other assets.
- [ ]	Caching & Incremental Builds: Implement caching to improve build performance when fetching content.
- [ ] Draft Previews: Add support for previewing unpublished (draft) posts.

## Testing

Testing isn’t fully set up yet, but contributions and improvements are welcome.

## Contributing

We welcome contributions to this project! To contribute:

1. Fork the repository
2. Create a new branch (git checkout -b feature-branch)
3. Make your changes
4. Push to the branch (git push origin feature-branch)
5. Open a Pull Request
