# frozen_string_literal: true

require_relative 'certgen/cli'
require_relative 'certgen/generator'

# Certgen: A high-performance CLI utility for automated SSL certificate orchestration.
#
# This tool abstracts the ACME v2 protocol (specifically Let's Encrypt) to provide
# a streamlined path for generating certificates using DNS-01 verification.
#
# Implementation Principle:
# - Minimalist but robust.
# - Leverages standard libraries (OpenSSL, FileUtils) wherever possible.
# - Designed for both direct CLI usage and programmatic integration.
#
# @author Rajan Bhattarai
# @since 0.1.0
module Certgen
  # Current version of the Certgen application.
  # We adhere to Semantic Versioning (https://semver.org/).
  VERSION = '0.1.0'

  # Base exception for the Certgen namespace.
  # Rescuing this allows consumers to handle all domain-level errors.
  class Error < StandardError; end

  # Programmatic entry point for triggering certificate generation.
  # Use this if you are integrating Certgen into a larger Ruby script or system.
  #
  # @param domain [String] The apex or subdomain to secure.
  # @param email [String] Contact email for the ACME registration.
  # @return [Boolean] Returns true if the process completes without exception.
  # @raise [Certgen::Error] if validation or API protocols fail.
  def self.generate(domain:, email:)
    Certgen::Generator.new(
      domain: domain,
      email: email
    ).run
  end
end
