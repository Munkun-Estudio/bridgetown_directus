# frozen_string_literal: true

require_relative "lib/bridgetown_directus/version"

Gem::Specification.new do |spec|
  spec.name          = "bridgetown_directus"
  spec.version       = BridgetownDirectus::VERSION
  spec.author        = "Munkun"
  spec.email         = "development@munkun.com"
  spec.summary       = "Use Directus as headless CMS for Bridgetown"
  spec.homepage      = "https://github.com/munkun-estudio/bridgetown_directus"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features|frontend)/!) }
  spec.test_files    = spec.files.grep(%r!^test/!)
  spec.require_paths = ["lib"]

  spec.metadata         = {
      "source_code_uri" => spec.homepage,
      "bug_tracker_uri" => "#{spec.homepage}/issues",
      "changelog_uri"   => "#{spec.homepage}/releases",
      "homepage_uri"    => spec.homepage
  }

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "bridgetown", ">= 1.2.0", "< 2.0"
  spec.add_dependency "faraday", "~> 2.12"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop-bridgetown", "~> 0.3"
  spec.add_development_dependency "shoulda", "~> 3.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-profile", "~> 0.0.2"
  spec.add_development_dependency "minitest-reporters", "~> 1.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
