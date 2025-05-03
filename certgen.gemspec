# frozen_string_literal: true

require_relative "lib/certgen/version"

Gem::Specification.new do |spec|
  spec.name = "certgen"
  spec.version = Certgen::VERSION
  spec.authors = ["Rajan Bhattarai"]
  spec.email = ["cdrrazan@gmail.com"]

  spec.summary = "A Ruby CLI gem to generate free SSL certificates using Let's Encrypt with DNS verification."
  spec.description = "Certgen is a command-line Ruby gem that helps users generate free SSL certificates from Let's Encrypt using DNS-01 verification. Ideal for users with manual or cPanel-based hosting environments. Supports wildcard domains and reusable account keys."
  spec.homepage = "https://github.com/cdrrazan/certgen"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cdrrazan/certgen"
  spec.metadata["changelog_uri"] = "https://github.com/cdrrazan/certgen/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)

  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.end_with?(".gem") || # <--- this line fixes it
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "acme-client"
  spec.add_dependency "optparse"
  spec.add_dependency "rubyzip"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
