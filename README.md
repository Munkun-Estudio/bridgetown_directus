# Bridgetown Directus Plugin

[![Gem Version](https://badge.fury.io/rb/bridgetown_directus.svg)](https://badge.fury.io/rb/bridgetown_directus)

This Bridgetown plugin integrates with [Directus](https://directus.io/), a flexible headless CMS. The plugin allows Bridgetown to pull content from a Directus API during the build process and generate static content in your site. It supports both single-language and multilingual content through Directus translations.

## Features

- Fetch content from **multiple Directus collections** during the build process
- Support for **flexible field mapping** and custom converters
- Support for **multilingual content** via Directus translations
- **Experimental**: Advanced **filtering, sorting, and pagination** options
- Simple configuration for any Bridgetown collection (posts, pages, or custom types)

## Installation

Before installing the plugin, make sure you have an [Auth Token](https://docs.directus.io/reference/authentication.html#access-tokens) in your Directus instance.

### Recommended Installation (Bridgetown Automation)

1. Run the plugin's automation setup:

   ```bash
   bin/bridgetown apply https://github.com/munkun-estudio/bridgetown_directus
   ```

   This will:
   - Prompt for your Directus API URL, token, Directus collection name, and Bridgetown collection name
   - Generate a minimal `config/initializers/bridgetown_directus.rb`
   - All further customization is done in Ruby, not YAML

### Manual Installation

1. Add the gem to your Gemfile:

   ```ruby
   bundle add "bridgetown_directus"
   ```

2. Run `bundle install` to install the gem.
3. Create `config/initializers/bridgetown_directus.rb` (see below for configuration).

## Configuration

### Minimal Example

```ruby
# config/initializers/bridgetown_directus.rb
init :bridgetown_directus do |directus|
  directus.api_url = ENV["DIRECTUS_API_URL"] || "https://your-directus-instance.com"
  directus.token = ENV["DIRECTUS_API_TOKEN"] || "your-token"

  directus.register_collection(:materials) do |c|
    c.endpoint = "imasus_materials"
    c.layout = "material" # Use the singular layout for individual pages
    # Minimal mapping (optional):
    c.field :id, "id"
    c.field :title, "title"
    # To enable translations, uncomment and edit:
    # c.enable_translations([:title, :content])
  end
end
```

For custom collections, create a layout file at `src/_layouts/[singular].erb` (e.g., `staff_member.erb`) to control the page rendering.

**By default, all Directus fields will be written to the front matter of generated Markdown files.**
You only need to declare fields with `c.field` if you want to:
- Rename a field in the output
- Transform/convert a field value (e.g., format a date, generate a slug, etc.)
- Set a default value if a field is missing

#### Example: Customizing a Field

```ruby
c.field :slug, "slug" do |value|
  value || "staff_member-#{SecureRandom.hex(4)}"
end
```

### Translations

To enable translations for specific fields, add this inside your collection block:

```ruby
c.enable_translations([:title, :content])
```

- You can list any field that exists in your Directus collection, even if it's not declared above with `c.field`.
- Only declare a field with `c.field` if you want to rename, transform, or set a default for it.

### File Generation & Cleanup

- **Generated files**: The plugin writes Markdown files to `src/_[bridgetown_collection]/` (e.g., `src/_materials/`).
- **Safety**: Only files with the `directus_generated: true` flag in their front matter are deleted during cleanup. User-authored files are never removed.

### Advanced Configuration

See the plugin source and inline documentation for advanced features such as:
- Multiple collections
- Custom layouts per collection
- Filtering, sorting, and pagination via `c.default_query` (**experimental**; not fully tested in production—see notes below)
- Selective field output

**Note:** Filtering, sorting, and pagination via `c.default_query` is experimental and not yet fully tested in real Bridgetown projects. Please report issues or contribute test cases if you use this feature!

### Migrating from 0.1.x

- **YAML config is no longer used.** All configuration is now in Ruby in `config/initializers/bridgetown_directus.rb`.
- Field mapping, transformation, and translations are handled in the initializer.
- All Directus fields are output by default; use `c.field` for customization.
- **Upgrading?** The `resource_type` option is no longer required. Use the Bridgetown collection name and layout instead. See the [CHANGELOG](CHANGELOG.md) for details.

---

For more details and advanced usage, see the [plugin README](https://github.com/Munkun-Estudio/bridgetown_directus).

See [CHANGELOG.md](CHANGELOG.md) for upgrade notes and detailed changes.
