# frozen_string_literal: true

require "certgen/cli"
require "certgen/generator"
require "certgen/version"

module Certgen
  # Custom error class for all Certgen-specific errors
  class Error < StandardError; end

  # Main entry point for generating certificates
  def self.generate(domain:, email:)
    Certgen::Generator.new(
      domain: domain,
      email: email
    ).run
  end
end
