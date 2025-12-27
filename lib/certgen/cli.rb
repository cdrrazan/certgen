# frozen_string_literal: true

require 'optparse'
require_relative 'generator'

module Certgen
  # CLI: The orchestration layer for the Command Line Interface.
  #
  # This class implements a standard subcommand pattern (generate/test) and handles
  # the translation of CLI flags into application-level configuration.
  #
  # It follows common Ruby CLI conventions:
  # - Informative usage banners
  # - Proper exit codes for errors (1) and interrupts (130)
  # - Separation of configuration parsing and execution logic
  class CLI
    # The primary entry point for the CLI executable.
    # Handles argument lifecycle and high-level exception management.
    #
    # @param argv [Array<String>] Raw arguments, primarily from ARGV.
    # @return [void]
    def self.start(argv)
      options = {}
      parser = create_option_parser(options)

      begin
        # Phase 1: Identify global flags and shortcuts (-v, -h).
        # We use #order! to stop at the first non-option (the subcommand).
        parser.order!(argv)
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
        abort "❌ Error: #{e.message}\n#{parser}"
      end

      # Phase 2: Extract the subcommand (the primary action).
      subcommand = argv.shift

      # Phase 3: Parse remaining flags provided specifically for the subcommand.
      begin
        parser.parse!(argv)
      rescue OptionParser::InvalidOption => e
        abort "❌ Error: #{e.message}\n#{parser}"
      end

      # Phase 4: Validation and Guarding.
      validate_subcommand!(subcommand, parser)
      validate_options!(options, parser)

      # Phase 5: Execution delegation.
      execute_command(subcommand, options)
    rescue Interrupt
      # Handle SIGINT (Ctrl+C) gracefully to prevent stack traces.
      puts "\n👋 Operation cancelled by user."
      exit 130
    rescue Certgen::Error => e
      # Expected domain errors are formatted and displayed with failure status.
      abort "❌ Application Error: #{e.message}"
    rescue StandardError => e
      # Unexpected failures include path/trace info if the DEBUG environment is set.
      abort "💥 Unexpected Error: #{e.message}\n#{e.backtrace.join("\n") if ENV['DEBUG']}"
    end

    # Configures the OptionParser instance that defines our CLI interface.
    #
    # @param options [Hash] A mutable hash used to store the parsed flag values.
    # @return [OptionParser]
    def self.create_option_parser(options)
      OptionParser.new do |opts|
        opts.banner = 'Usage: certgen [command] [options]'

        opts.separator ''
        opts.separator 'Available Commands:'
        opts.separator '    generate     Issue a production SSL certificate (subject to rate limits)'
        opts.separator "    test         Use Let's Encrypt Staging for validation/testing"

        opts.separator ''
        opts.separator 'Global Options:'

        opts.on('-d', '--domain DOMAIN',
                "The target domain (e.g., 'example.com'). Includes 'www' automatically.") do |v|
          options[:domain] = v
        end

        opts.on('-e', '--email EMAIL', 'Contact email for ACME account registration.') do |v|
          options[:email] = v
        end

        opts.on('-v', '--version', 'Display version information.') do
          puts "Certgen v#{Certgen::VERSION}"
          exit
        end

        opts.on('-h', '--help', 'Show this help message.') do
          puts opts
          exit
        end
      end
    end

    # Validates that a recognized subcommand was provided.
    #
    # @param subcommand [String, nil]
    # @param parser [OptionParser] Used to display help on failure.
    # @return [void]
    def self.validate_subcommand!(subcommand, parser)
      return if %w[generate test].include?(subcommand)

      message = subcommand ? "Unknown command: '#{subcommand}'" : 'No command provided'
      abort "❌ #{message}\n#{parser}"
    end

    # Ensures mandatory prerequisites for certificate issuance are present.
    #
    # @param options [Hash]
    # @param parser [OptionParser]
    # @return [void]
    def self.validate_options!(options, parser)
      missing = []
      missing << '--domain' unless options[:domain]
      missing << '--email' unless options[:email]

      return if missing.empty?

      abort "❌ Missing required options: #{missing.join(', ')}\n#{parser}"
    end

    # Routes the validated request to the core Generator engine.
    #
    # @param subcommand [String]
    # @param options [Hash]
    # @return [void]
    def self.execute_command(subcommand, options)
      is_staging = (subcommand == 'test')

      Generator.new(
        domain: options[:domain],
        email: options[:email],
        staging: is_staging
      ).run
    end
  end
end
