# Releasing `bridgetown_directus`

This document explains the release workflow for this gem and how to recover if automation fails.

## Overview

There are three parts:

1. **release-please** creates a release PR and a `bridgetown_directus/vX.Y.Z` tag.
2. **Release** workflow publishes the gem to RubyGems via OIDC Trusted Publishing.
3. **CI** runs tests on PRs and pushes.

## Normal automated release flow (recommended)

1. **Make changes on a branch** and merge to `main` with a Conventional Commit title:
   - `fix:` → patch (e.g., `0.4.2`)
   - `feat:` → minor (e.g., `0.5.0`)
   - `feat!:` or `BREAKING CHANGE:` → major (e.g., `1.0.0`)
   - `ci:`, `chore:`, `docs:` → **no version bump** (use these for workflow/docs changes)
2. `release-please` runs on push to `main` and **opens a release PR**.
3. Merge the release PR:
   - `release-please` **creates a tag** `bridgetown_directus/vX.Y.Z` and a GitHub Release.
4. The **Release workflow** triggers on the tag, authenticates via OIDC, and **publishes to RubyGems**.

### Requirements for the automated flow

- A **PAT** stored as the repo secret `RELEASE_PLEASE_TOKEN` so the tag created by release-please triggers other workflows.
- RubyGems **Trusted Publisher** configured for this repo/workflow (see below).

## Workflows (GitHub Actions)

### CI

File: `.github/workflows/ci.yml`
Runs tests on PRs and pushes.

### Release Please

File: `.github/workflows/release-please.yml`
Creates release PRs and tags in the format `bridgetown_directus/vX.Y.Z`.

Important: it uses a PAT:

```yaml
token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
```

### Release

File: `.github/workflows/release.yml`
Triggers on tags matching `bridgetown_directus/v*`.

Steps:

1. Checkout code
2. Setup Ruby 3.4 with bundler cache
3. Run tests
4. Build gem via `rake build`
5. Configure RubyGems credentials via OIDC (`rubygems/configure-rubygems-credentials@v1.0.0`)
6. Push gem via `gem push`

**Note:** This workflow does **not** use `rake release` or `rubygems/release-gem@v1` because those attempt to create and push git tags, which conflicts with release-please's tagging (detached HEAD on tag checkout). Instead, it uses `configure-rubygems-credentials` for OIDC authentication and `gem push` directly.

## Secrets you need

1. **RELEASE_PLEASE_TOKEN** (GitHub PAT, classic token with `repo` scope)
   - Used by release-please to create tags that trigger the Release workflow.

> NOTE: `RUBYGEMS_API_KEY` is no longer needed. Authentication is handled via OIDC Trusted Publishing.

## RubyGems Trusted Publishing setup

1. Go to RubyGems → your gem → **Trusted Publishers** → **Create**.
2. Fill in:
   - Owner: `Munkun-Estudio` (case-sensitive — must match GitHub org exactly)
   - Repo: `bridgetown_directus`
   - Workflow file: `release.yml`
   - Environment: leave blank
3. Save.

After this, GitHub can publish without API keys or OTP, even with MFA set to "UI and API".

## Tag format

release-please uses the format `bridgetown_directus/vX.Y.Z` (configured in `.release-please-config.json`). The Release workflow matches this pattern. Do **not** create plain `vX.Y.Z` tags — they won't trigger the workflow.

## Local release (manual fallback)

Use this if the Release workflow fails or you need to publish immediately:

```bash
bundle exec rake build
gem push pkg/bridgetown_directus-X.Y.Z.gem
```

If RubyGems MFA is set to "UI and API", you will be prompted for an OTP.

## Troubleshooting

### Release PR merged but gem not published

Likely cause: tag created by `release-please` didn't trigger the Release workflow.
Fix: ensure `RELEASE_PLEASE_TOKEN` is set and the workflow uses it.

### "No trusted publisher configured" error

Check that the Trusted Publisher on RubyGems.org matches exactly:

- Owner casing: `Munkun-Estudio` (not `munkun-estudio`)
- Workflow filename: `release.yml`
- Environment: blank

### "refs/heads/HEAD does not match" error

This happens when using `rubygems/release-gem@v1` or `rake release` from a tag checkout (detached HEAD). The current workflow avoids this by using `gem push` directly instead of `rake release`.

### Unwanted version bumps from CI fixes

Use `ci:` or `chore:` commit prefixes for workflow changes. Only `fix:` and `feat:` trigger version bumps.

## Version file

`lib/bridgetown_directus/version.rb` is updated by release-please.
Do **not** bump it manually.

## Changelog

`CHANGELOG.md` is updated by release-please. Keep entries under `Unreleased` if editing manually.
