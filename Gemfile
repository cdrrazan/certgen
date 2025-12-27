# frozen_string_literal: true

# ---
# Certgen Dependency Manifest
# Defines the required gems for production runtime and developer tooling.
# We favor pessimistic version constraints (~>) to ensure API stability.
# ---

source 'https://rubygems.org'

# --- Runtime Dependencies ---

# RFC 8555 (ACME) protocol implementation for Let's Encrypt.
gem 'acme-client', '~> 2.0.21'

# Provides support for generating .zip bundles from certificate files.
gem 'rubyzip', '~> 2.4'

# Resilient HTTP transport layers with retry logic for ACME server reliability.
gem 'faraday-net_http', '~> 3.4'
gem 'faraday-retry', '~> 2.3'

# Standard utility libraries for processing JSON payloads and system logging.
gem 'json', '~> 2.11'
gem 'logger', '~> 1.7'

# --- Development & Testing Tools ---
group :development, :test do
  # Standard Ruby task runner and testing framework.
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.0'

  # Professional Linting: Ensures adherence to community style guides.
  gem 'rubocop', '~> 1.71'
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
end
