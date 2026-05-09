# Changelog

## Unreleased

### Added
- `npm ci`-based deterministic smoke check for the local reviewer command in CI.
- `review`, `smoke-review`, and `ci-review` scripts in `package.json` to make the skill review entrypoint easier to run.
- Added `CHANGELOG.md` for release-note style tracking.

### Changed
- Refined the `skill-rating-pipeline` workflow to use `npm ci` before running the reviewer CLI smoke test.
