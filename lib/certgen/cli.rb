# frozen_string_literal: true

require "optparse"
require_relative "generator"

module Certgen
  class CLI
    def self.start(argv)
      options = {}
      subcommand = argv.shift

      parser = OptionParser.new do |opts|
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

      begin
        parser.parse!(argv)
      rescue OptionParser::InvalidOption => e
        puts "❌ #{e.message}"
        puts parser
        exit 1
      end

      unless %w[generate test].include?(subcommand)
        puts "❌ Unknown command: #{subcommand}"
        puts parser
        exit 1
      end

      unless options[:domain] && options[:email]
        puts "❌ Both --domain and --email are required"
        puts parser
        exit 1
      end

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
