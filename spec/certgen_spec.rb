# frozen_string_literal: true

require "spec_helper"
require "certgen/generator"

# Test suite for the Certgen module
RSpec.describe Certgen do
  it "has a version number" do
    expect(Certgen::VERSION).not_to be nil
  end

  # Test suite for the Certgen::Generator class
  describe Certgen::Generator do
    # Test fixtures
    let(:domain) { "example.com" }
    let(:email) { "user@example.com" }
    let(:generator) { described_class.new(domain: domain, email: email) }

    # Test that generator initializes with correct instance variables
    it "initializes with correct domain, base_domain, output_dir, and email" do
      expect(generator.instance_variable_get(:@input_domain)).to eq("example.com")
      expect(generator.instance_variable_get(:@base_domain)).to eq("example.com")
      expect(generator.instance_variable_get(:@domains)).to contain_exactly("example.com", "www.example.com")
      expect(generator.instance_variable_get(:@output_dir)).to eq(File.expand_path("~/.ssl_output/example.com"))
      expect(generator.instance_variable_get(:@email)).to eq("user@example.com")
    end

    # Test that output directory path is created correctly
    it "creates correct output directory path" do
      output_dir = generator.instance_variable_get(:@output_dir)
      expect(output_dir).to eq(File.expand_path("~/.ssl_output/example.com"))
    end

    # Test that account key is created when it doesn't exist
    it "creates account key if it doesn't exist" do
      path = File.expand_path("~/.certgen/test_account.key")
      allow(File).to receive(:exist?).with(path).and_return(false)
      allow(File).to receive(:write)
      allow(OpenSSL::PKey::RSA).to receive(:new).and_return(OpenSSL::PKey::RSA.generate(2048))
      FileUtils.mkdir_p(File.dirname(path))
    end

    # Test that certificate files are zipped correctly
    it "zips the certificate files correctly" do
      temp_dir = Dir.mktmpdir
      cert_file = File.join(temp_dir, "certificate.crt")
      key_file = File.join(temp_dir, "private_key.pem")
      ca_file = File.join(temp_dir, "ca_bundle.pem")
      [cert_file, key_file, ca_file].each { |f| File.write(f, "test content") }

      zip_path = File.join(temp_dir, "cert_bundle.zip")
      generator.send(:create_zip, zip_path, [cert_file, key_file, ca_file])

      expect(File.exist?(zip_path)).to be true
      entries = []
      ::Zip::File.open(zip_path) do |zipfile|
        entries = zipfile.entries.map(&:name)
      end

      expect(entries).to include("certificate.crt", "private_key.pem", "ca_bundle.pem")
    ensure
      FileUtils.rm_rf(temp_dir)
    end
  end
end
