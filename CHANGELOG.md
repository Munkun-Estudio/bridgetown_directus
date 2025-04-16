# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
