# frozen_string_literal: true

require 'optparse'
require_relative 'generator'

module Certgen
  # CLI: The command-line interface layer for Certgen.
  #
  # This class handles argument parsing, subcommand routing, and basic input validation.
  # It leverages Ruby's standard 'optparse' library for a native feel and robust flag handling.
  class CLI
    # Entry point for the CLI application.
    # Parses top-level commands and delegates to specific handlers.
    #
    # @param argv [Array<String>] The raw command-line arguments (usually ARGV).
    def self.start(argv)
      options = {}
      parser = create_option_parser(options)

      begin
        # Parse global flags (like -v, -h) before shifting the subcommand
        # This allows 'certgen -v' to work without a subcommand.
        parser.order!(argv)
      rescue OptionParser::InvalidOption => e
        abort "❌ Error: #{e.message}\n#{parser}"
      rescue OptionParser::MissingArgument => e
        abort "❌ Error: #{e.message}\n#{parser}"
      end

      # After parsing global options, the first remaining element is our subcommand
      subcommand = argv.shift

      # Parse remaining arguments to catch flags provided after the subcommand
      begin
        parser.parse!(argv)
      rescue OptionParser::InvalidOption => e
        abort "❌ Error: #{e.message}\n#{parser}"
      end

      # Validate that we have a valid action to perform
      validate_subcommand!(subcommand, parser)
      # Ensure mandatory identity/domain details are present
      validate_options!(options, parser)

      # Execution phase
      execute_command(subcommand, options)
    rescue Interrupt
      # Handle Ctrl+C gracefully
      puts "\n👋 Operation cancelled by user."
      exit 130
    rescue Certgen::Error => e
      # Domain-specific errors handled with clean output
      abort "❌ Application Error: #{e.message}"
    rescue StandardError => e
      # Unexpected failures include backtrace for debugging if needed
      abort "💥 Unexpected Error: #{e.message}\n#{e.backtrace.join("\n") if ENV['DEBUG']}"
    end

    # Configures the OptionParser instance with supported flags.
    #
    # @param options [Hash] Mutable state to store parsed configuration.
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

    # Ensures the provided subcommand is recognized by the system.
    def self.validate_subcommand!(subcommand, parser)
      return if %w[generate test].include?(subcommand)

      message = subcommand ? "Unknown command: '#{subcommand}'" : 'No command provided'
      abort "❌ #{message}\n#{parser}"
    end

    # Validates presence of mandatory flags for cert generation.
    def self.validate_options!(options, parser)
      missing = []
      missing << '--domain' unless options[:domain]
      missing << '--email' unless options[:email]

      return if missing.empty?

      abort "❌ Missing required options: #{missing.join(', ')}\n#{parser}"
    end

    # Routes execution to the appropriate Generator instance.
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
