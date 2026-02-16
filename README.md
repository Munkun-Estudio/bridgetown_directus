# Bridgetown Directus Plugin

[![Gem Version](https://badge.fury.io/rb/bridgetown_directus.svg)](https://badge.fury.io/rb/bridgetown_directus)

A [Bridgetown](https://www.bridgetownrb.com/) plugin that syncs content from [Directus](https://directus.io/) at build time. It fetches collections from the Directus API and either generates static Markdown files or injects data directly into `site.data`.

## Features

- **Output collections** — fetch Directus items and generate Markdown files (posts, pages, custom types)
- **Data collections** — fetch Directus items and inject into `site.data` (no file generation)
- **Singletons** — single-object collections (e.g. site settings)
- **M2M junction flattening** — unwrap Directus many-to-many junction objects automatically
- **Flexible field mapping** with custom converters
- **Multilingual content** via Directus translations
- **Configurable SSL verification** for environments with strict OpenSSL
- **Graceful skip** — build succeeds even without Directus credentials configured

## Installation

### Recommended (Bridgetown Automation)

```bash
bin/bridgetown apply https://github.com/munkun-estudio/bridgetown_directus
```

### Manual

```ruby
bundle add "bridgetown_directus"
```

```bash
bundle install
```

## Configuration

### Basic Setup

```ruby
# config/initializers.rb
init :bridgetown_directus

BridgetownDirectus.configure do |directus|
  directus.api_url = ENV["DIRECTUS_API_URL"]
  directus.token   = ENV["DIRECTUS_API_TOKEN"]

  directus.register_collection(:posts) do |c|
    c.endpoint = "blog_posts"
    c.layout   = "post"
  end
end
```

The plugin reads `DIRECTUS_API_URL` and `DIRECTUS_API_TOKEN` from the environment by default. If neither is set, the build skips Directus sync gracefully.

### Data Collections

Data collections populate `site.data` without generating files. Useful for navigation, settings, or any shared data.

```ruby
directus.register_collection(:navigation) do |c|
  c.endpoint      = "navigation_items"
  c.resource_type = :data
  c.default_query = {
    sort: "sort",
    filter: { status: { _eq: "published" } }.to_json
  }
end
```

Access in templates via `site.data.navigation`.

### Singletons

For collections that contain a single record (e.g. site settings):

```ruby
directus.register_collection(:site_settings) do |c|
  c.endpoint      = "site_settings"
  c.resource_type = :data
  c.singleton     = true
end
```

Returns a single hash instead of an array. Access via `site.data.site_settings`.

### Output Collections

Generate Markdown files for posts, pages, or custom collection types:

```ruby
directus.register_collection(:events) do |c|
  c.endpoint      = "events"
  c.resource_type = :custom_collection
  c.layout        = "event"
  c.default_query = {
    filter: { status: { _eq: "published" } }.to_json
  }
end
```

Generated files include `directus_generated: true` in front matter. Only these files are cleaned up on rebuild — user-authored files are never deleted.

### M2M Junction Flattening

Directus returns many-to-many relationships wrapped in junction objects:

```json
[{ "raus_stats_id": { "id": 1, "value": "8+" } }]
```

Use `flatten_m2m` to unwrap them:

```ruby
directus.register_collection(:pages) do |c|
  c.endpoint      = "pages"
  c.resource_type = :data
  c.default_query = {
    fields: "id,title,sections.stats.raus_stats_id.*"
  }
  c.flatten_m2m "sections.stats", key: "raus_stats_id"
end
```

After flattening:

```json
[{ "id": 1, "value": "8+" }]
```

### Field Mapping

All Directus fields are included in the output by default. Use `c.field` only when you need to rename or transform a value:

```ruby
c.field :slug, "slug" do |value|
  value || "fallback-#{SecureRandom.hex(4)}"
end
```

### Translations

```ruby
c.enable_translations([:title, :content])
```

### SSL Verification

If your local OpenSSL (3.6+) fails with CRL verification errors, you can disable SSL verification:

```ruby
directus.ssl_verify = false
```

This is a client-side issue with recent OpenSSL versions that enforce CRL checking but cannot auto-download CRLs during the TLS handshake. It typically only affects local development — CI/CD environments use standard OpenSSL builds without this issue.

Default: `true`.

### Debug Logging

```bash
BRIDGETOWN_DIRECTUS_LOG=1 bin/bt build
```

### Environment Variables

| Variable | Description |
| -------- | ----------- |
| `DIRECTUS_API_URL` | Directus instance URL |
| `DIRECTUS_API_TOKEN` | Static access token |
| `DIRECTUS_TOKEN` | Legacy fallback for token |
| `BRIDGETOWN_DIRECTUS_LOG` | Set to `1` for verbose logging |

## Full Example

```ruby
# config/initializers.rb
init :bridgetown_directus

BridgetownDirectus.configure do |directus|
  directus.api_url    = ENV["DIRECTUS_API_URL"]
  directus.token      = ENV["DIRECTUS_API_TOKEN"]
  directus.ssl_verify = false

  # Data-only: populates site.data
  directus.register_collection(:site_settings) do |c|
    c.endpoint      = "site_settings"
    c.resource_type = :data
    c.singleton     = true
  end

  directus.register_collection(:navigation) do |c|
    c.endpoint      = "navigation_items"
    c.resource_type = :data
    c.default_query = { sort: "sort" }
  end

  # Output: generates Markdown files
  directus.register_collection(:events) do |c|
    c.endpoint      = "events"
    c.resource_type = :custom_collection
    c.layout        = "event"
    c.default_query = {
      filter: { status: { _eq: "published" } }.to_json
    }
  end
end
```

## Migrating from 0.2.x

- Configuration now uses `BridgetownDirectus.configure` block after `init :bridgetown_directus`
- New `resource_type: :data` for collections that inject into `site.data`
- New `singleton: true` for single-record collections
- New `flatten_m2m` for M2M junction unwrapping
- Build no longer fails when Directus credentials are missing — it skips gracefully
- SSL verification is configurable via `ssl_verify`

See [CHANGELOG.md](CHANGELOG.md) for upgrade notes and detailed changes.

## License

See [LICENSE](LICENSE) for details.
