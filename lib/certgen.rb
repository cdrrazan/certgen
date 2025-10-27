# frozen_string_literal: true

require "certgen/cli"
require "certgen/generator"
require "certgen/version"

# Main module for the Certgen gem
# Provides a simple interface for generating SSL certificates using Let's Encrypt
#
# @example Generate a certificate
#   Certgen.generate(domain: "example.com", email: "user@example.com")
module Certgen
  # Custom error class for all Certgen-specific errors
  class Error < StandardError; end

  # Generates an SSL certificate for the given domain
  #
  # @param domain [String] The domain name to issue the certificate for
  # @param email [String] Email address for Let's Encrypt registration
  # @return [void]
  # @raise [Error] If certificate generation fails
  def self.generate(domain:, email:)
    Certgen::Generator.new(
      domain: domain,
      email: email
    ).run
  end
end
