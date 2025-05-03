# frozen_string_literal: true

require_relative "certgen/version"
require "certgen/cli"
require "certgen/generator"

module Certgen
  # Custom error class for all Certgen-specific errors
  class Error < StandardError; end

  # Main entry point for generating certificates
  def self.generate(domain:, email:)
    Certgen::Generator.new(
      domain:,
      email:
    ).run
  end
end
