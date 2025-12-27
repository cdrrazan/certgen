# frozen_string_literal: true

require_relative 'certgen/cli'
require_relative 'certgen/generator'

# Certgen: A streamlined CLI tool for automated SSL certificate generation.
#
# This module serves as the primary namespace and public API for the Certgen application.
# It encapsulates versioning, error handling, and high-level orchestration logic.
#
# @author Rajan Bhattarai
# @since 0.1.0
module Certgen
  # Current version of the Certgen tool. Follows Semantic Versioning (SemVer).
  VERSION = '0.1.0'

  # Base exception class for all domain-specific errors within the Certgen namespace.
  # Rescuing this allows callers to handle all Certgen-related failures predictably.
  class Error < StandardError; end

  # High-level convenience method to trigger certificate generation.
  # This provides a clean Ruby API for consumers who might want to use Certgen
  # programmatically rather than via the CLI.
  #
  # @param domain [String] The apex domain or subdomain to secure.
  # @param email [String] Contact email for Let's Encrypt account registration.
  # @return [Boolean] Returns true if the process completes successfully.
  # @raise [Certgen::Error] If generation fails due to validation or API errors.
  #
  # @example
  #   Certgen.generate(domain: "example.com", email: "admin@example.com")
  def self.generate(domain:, email:)
    Certgen::Generator.new(
      domain: domain,
      email: email
    ).run
  end
end
