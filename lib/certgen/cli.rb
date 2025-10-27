# frozen_string_literal: true

require "optparse"
require_relative "generator"

module Certgen
  # Command-line interface for Certgen
  # Handles parsing command-line arguments and executing the appropriate commands
  class CLI
    # Starts the CLI application
    #
    # @param argv [Array<String>] Command-line arguments
    # @return [void]
    def self.start(argv)
      options = {}
      subcommand = argv.shift

      parser = create_option_parser(options)

      begin
        parser.parse!(argv)
      rescue OptionParser::InvalidOption => e
        puts "❌ #{e.message}"
        puts parser
        exit 1
      end

      validate_subcommand!(subcommand, parser)
      validate_options!(options, parser)

      execute_command(subcommand, options)
    end

    # Creates and configures the option parser
    #
    # @param options [Hash] Hash to store parsed options
    # @return [OptionParser] Configured option parser
    def self.create_option_parser(options)
      OptionParser.new do |opts|
        opts.banner = "Usage: certgen [command] [options]"

        opts.separator ""
        opts.separator "Commands:"
        opts.separator "    generate     Generate a real SSL certificate using Let's Encrypt"
        opts.separator "    test         Test certificate generation using the Let's Encrypt staging environment (no rate limits)"
        opts.separator ""
        opts.separator "Options:"

        opts.on("--domain DOMAIN", "The domain to issue a certificate for (e.g., example.com)") do |v|
          options[:domain] = v
        end

        opts.on("--email EMAIL", "Email address for Let's Encrypt registration") do |v|
          options[:email] = v
        end

        opts.on("-h", "--help", "Print this help message") do
          puts opts
          exit
        end
      end
    end

    # Validates that the subcommand is valid
    #
    # @param subcommand [String] The command to validate
    # @param parser [OptionParser] The parser to display help if invalid
    # @return [void]
    # @raise [SystemExit] If subcommand is invalid
    def self.validate_subcommand!(subcommand, parser)
      return if %w[generate test].include?(subcommand)

      puts "❌ Unknown command: #{subcommand}"
      puts parser
      exit 1
    end

    # Validates that required options are present
    #
    # @param options [Hash] The parsed options
    # @param parser [OptionParser] The parser to display help if invalid
    # @return [void]
    # @raise [SystemExit] If required options are missing
    def self.validate_options!(options, parser)
      return if options[:domain] && options[:email]

      puts "❌ Both --domain and --email are required"
      puts parser
      exit 1
    end

    # Executes the appropriate command based on the subcommand
    #
    # @param subcommand [String] The command to execute
    # @param options [Hash] The parsed options
    # @return [void]
    def self.execute_command(subcommand, options)
      case subcommand
      when "generate"
        Certgen::Generator.new(domain: options[:domain], email: options[:email]).run
      when "test"
        Certgen::Generator.new(domain: options[:domain], email: options[:email], staging: true).run
      else
        puts "Unknown command. Available: generate, test"
        exit 1
      end
    end
  end
end
