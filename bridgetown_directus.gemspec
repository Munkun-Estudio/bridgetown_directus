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

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "bridgetown", ">= 1.2.0", "< 2.0"
  spec.add_dependency "faraday", "~> 2.12"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rubocop-bridgetown", "~> 0.3"
  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-profile"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "webmock"
end
