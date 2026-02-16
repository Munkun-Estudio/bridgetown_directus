# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.2](https://github.com/Munkun-Estudio/bridgetown_directus/compare/bridgetown_directus/v0.4.1...bridgetown_directus/v0.4.2) (2026-02-16)


### Bug Fixes

* use OIDC credentials with gem push instead of rake release ([063adf1](https://github.com/Munkun-Estudio/bridgetown_directus/commit/063adf1b33d798da31467f9ae7790962ed41ef30))

## [0.4.1](https://github.com/Munkun-Estudio/bridgetown_directus/compare/bridgetown_directus/v0.4.0...bridgetown_directus/v0.4.1) (2026-02-16)


### Bug Fixes

* match release-please tag format in release workflow ([70bd081](https://github.com/Munkun-Estudio/bridgetown_directus/commit/70bd08125477acb33f10e06de5fd41ba889d472a))

## [0.4.0](https://github.com/Munkun-Estudio/bridgetown_directus/compare/bridgetown_directus/v0.3.0...bridgetown_directus/v0.4.0) (2026-02-16)


### Features

* add data collections, singleton support, flatten_m2m, and BridgetownDirectus.configure API ([31e99ac](https://github.com/Munkun-Estudio/bridgetown_directus/commit/31e99ac31463b944d20de1e81931219d2c0de59a))
* make SSL verify configurable via Configuration#ssl_verify ([6cb9033](https://github.com/Munkun-Estudio/bridgetown_directus/commit/6cb90331b0b2e99bd26ecde862c26d6969b0fbf6))

## [0.3.0](https://github.com/Munkun-Estudio/bridgetown_directus/compare/bridgetown_directus-v0.2.0...bridgetown_directus/v0.3.0) (2026-01-27)


### Features

* improve builder mapping and release automation ([b87c719](https://github.com/Munkun-Estudio/bridgetown_directus/commit/b87c719cfec175a86bc1f9388c308c496035d2cf))

## [Unreleased]

- ...

## [0.2.0] - 2025-04-16

- BREAKING: Simplified configuration—`resource_type` is no longer required. Use the Bridgetown collection name and layout instead.
- Automation now prompts for both Directus and Bridgetown collection names and sets up the initializer accordingly.
- Generated files are now flagged with `directus_generated: true` in front matter for safe cleanup.
- Only plugin-generated files (with this flag) are deleted during cleanup; user-authored files are preserved.
- Layouts for custom collections are now singular (e.g., `staff_member.erb`).
- README and example configuration updated for new conventions.
- Test suite updated for custom collections and file safety logic.

## [0.1.0] - 2024-09-27

- First version
