# frozen_string_literal: true

source 'https://rubygems.org'

# --- Runtime Dependencies ---

# ACME protocol client for Let's Encrypt / RFC 8555
gem 'acme-client', '~> 2.0.21'

# ZIP archive manipulation for certificate bundling
gem 'rubyzip',     '~> 2.4'

# HTTP Transport & Resiliency
gem 'faraday-net_http', '~> 3.4'
gem 'faraday-retry',    '~> 2.3'

# Core Utilities
gem 'json',   '~> 2.11'
gem 'logger', '~> 1.7'

# --- Development & Testing ---
group :development, :test do
  gem 'rake',    '~> 13.0'
  gem 'rspec',   '~> 3.0'
  gem 'rubocop', '~> 1.21'
end
