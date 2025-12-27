# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed

- Converted project from a Ruby Gem to a standalone CLI application.
- Consolidated versioning into the main `Certgen` module.
- Simplified directory structure: moved executable to `bin/` and removed
  gemspec-related files.
- Refactored internal `require` calls to `require_relative` for local
  portability.
- Enhanced CLI with `OptionParser#order!` for better global flag handling (e.g.,
  `-v`, `-h`).
- Improved documentation with expert-level YARD comments.
- Added comprehensive RSpec test suite with ACME protocol mocks.

### Fixed

- Fixed CLI flag parsing order to support global flags regardless of position.
- Silenced system output during unit tests for cleaner RSpec reports.

