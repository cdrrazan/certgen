# frozen_string_literal: true

require "optparse"
require_relative "generator"

module Certgen
  class CLI
    def self.start(argv)
      options = {}
      subcommand = argv.shift

      OptionParser.new do |opts|
        opts.banner = "Usage: certgen [command] [options]"
        opts.on("--domain DOMAIN", "The domain to test") { |v| options[:domain] = v }
        opts.on("--email EMAIL", "Contact email for registration") { |v| options[:email] = v }
      end.parse!(argv)

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
