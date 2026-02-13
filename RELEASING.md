# Releasing `bridgetown_directus`

This document explains the release workflow for this gem and how to recover if automation fails.

## Overview

There are three parts:

1. **release-please** creates a release PR and a `vX.Y.Z` tag.
2. **Release** workflow publishes the gem to RubyGems.
3. **CI** runs tests on PRs and pushes.

## Normal automated release flow (recommended)

1. **Make changes on a branch** and merge to `main` with a Conventional Commit title:
   - `fix:` → patch (e.g., `0.3.1`)
   - `feat:` → minor (e.g., `0.4.0`)
   - `feat!:` or `BREAKING CHANGE:` → major (e.g., `1.0.0`)
2. `release-please` runs on push to `main` and **opens a release PR**.
3. Merge the release PR:
   - `release-please` **creates a tag** `vX.Y.Z` and a GitHub Release.
4. The **Release workflow** runs on the tag and **publishes to RubyGems** via Trusted Publishing.

### Requirements for the automated flow

- A **PAT** stored as the repo secret `RELEASE_PLEASE_TOKEN` so the tag created by release-please triggers other workflows.
- RubyGems **Trusted Publisher** configured for this repo/workflow (see below).

## Workflows (GitHub Actions)

### CI

File: `.github/workflows/ci.yml`  
Runs tests on PRs and pushes.

### Release Please

File: `.github/workflows/release-please.yml`  
Creates release PRs and tags.

Important: it uses a PAT:

```yaml
token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
```

### Release

File: `.github/workflows/release.yml`  
Runs tests and publishes using OIDC (Trusted Publishing).

## Secrets you need

1. **RELEASE_PLEASE_TOKEN** (GitHub PAT, classic token with `repo` scope)
   - Used by release-please to create tags that trigger the Release workflow.

> NOTE: You no longer need `RUBYGEMS_API_KEY` once Trusted Publishing is configured.

## RubyGems Trusted Publishing setup

1. Go to RubyGems → your gem → **Trusted Publishers** → **Create**.
2. Fill in:
   - Owner: `Munkun-Estudio`
   - Repo: `bridgetown_directus`
   - Workflow file: `release.yml`
   - Environment: leave blank (unless you use one in GitHub)
3. Save.

After this, GitHub can publish without API keys or OTP.

## Local release (manual fallback)

Use this if the Release workflow fails or you need to publish immediately:

```bash
cd /Users/pablo/projects/bridgetown_directus
bundle install
bundle exec rake build
ls pkg
gem push pkg/bridgetown_directus-X.Y.Z.gem
```

If RubyGems MFA is enabled, you will be prompted for an OTP.

## Troubleshooting

### Release PR merged but gem not published

Likely cause: tag created by `release-please` didn’t trigger the Release workflow.
Fix: ensure `RELEASE_PLEASE_TOKEN` is set and the workflow uses it.

### Release workflow failed with MFA/OTP

You are not using Trusted Publishing. Configure it as above, then re-run the Release workflow.

### Tag exists but no Release workflow run

1. Verify the tag is `vX.Y.Z`.
2. Go to **Actions → Release → Run workflow** (manual run).
3. If it still fails, check the workflow logs.

## Version file

`lib/bridgetown_directus/version.rb` is updated by release-please.
Do **not** bump it manually if you use release-please.

## Changelog

`CHANGELOG.md` is updated by release-please. Keep entries under `Unreleased` if editing manually.
