# frozen_string_literal: true

# lib/certgen/cli.rb

require "optparse"

module Certgen
  class CLI
    def self.start
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: certgen [options]"

        opts.on("-d", "--domain DOMAIN", "Domain name") { |v| options[:domain] = v }
        opts.on("-e", "--email EMAIL", "Email address") { |v| options[:email] = v }
        opts.on("-w", "--wildcard", "Request a wildcard certificate") { options[:wildcard] = true }
        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end
      end.parse!

      unless options[:domain] && options[:email]
        puts "Error: Domain and email are required."
        exit 1
      end

      puts "[INFO] Starting certificate generation for #{options[:domain]}..."
      Certgen.generate(
        domain: options[:domain],
        email: options[:email]
      )
    end
  end
end
