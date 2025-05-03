# frozen_string_literal: true

require "acme-client"
require "fileutils"
require "openssl"
require "zip"

module Certgen
  class Generator
    LETS_ENCRYPT_DIRECTORY = "https://acme-v02.api.letsencrypt.org/directory"
    ACCOUNT_KEY_PATH = File.expand_path("~/.certgen/acme_account.key")

    def initialize(domain:, email:, staging: false)
      @input_domain = domain
      @email = email
      @staging = staging
      @directory_url = staging ?
        "https://acme-staging-v02.api.letsencrypt.org/directory" :
        "https://acme-v02.api.letsencrypt.org/directory"
      @base_domain = domain.sub(/^www\./, "")
      @domains = [@base_domain, "www.#{@base_domain}"].uniq
      @output_dir = File.expand_path("~/.ssl_output/#{@base_domain}")
    end

    def run
      ensure_account_key!
      setup_client
      create_output_directory
      order_certificate
      verify_dns_challenges
      finalize_certificate
      save_certificate_files
      notify_user
    end

    private

    def ensure_account_key!
      FileUtils.mkdir_p(File.dirname(ACCOUNT_KEY_PATH))
      if File.exist?(ACCOUNT_KEY_PATH)
        puts "🔐 Loading existing ACME account key..."
        @account_key = OpenSSL::PKey::RSA.new(File.read(ACCOUNT_KEY_PATH))
      else
        puts "🛠 Generating new ACME account key..."
        @account_key = OpenSSL::PKey::RSA.new(4096)
        File.write(ACCOUNT_KEY_PATH, @account_key.to_pem)
      end
    end

    def setup_client
      @client = Acme::Client.new(
        private_key: @account_key,
        directory: @directory_url
      )

      begin
        @client.new_account(contact: "mailto:#{@email}", terms_of_service_agreed: true)
      rescue Acme::Client::Error::Malformed
        puts "❌ ACME account already registered."
      end
    end

    def create_output_directory
      if Dir.exist?(@output_dir)
        puts "🧹 Cleaning existing output directory: #{@output_dir}"
        FileUtils.rm_rf(@output_dir)
      end
      FileUtils.mkdir_p(@output_dir)
    end

    def order_certificate
      @order = @client.new_order(identifiers: @domains)
      @authorizations = @order.authorizations
    end

    def verify_dns_challenges
      @authorizations.each do |auth|
        domain = auth.identifier["value"]
        challenge = auth.dns

        dns_record = "_acme-challenge.#{domain}"
        puts "\n📌 Please create this DNS TXT record for domain: #{domain}"
        puts "Record Name: #{dns_record}"
        puts "Record Type: TXT"
        puts "Record Value: #{challenge.record_content}"
        puts "\n⚠️ After adding it, wait for DNS to propagate (~1–5 minutes)."
        puts "🔎 Use https://dnschecker.org to confirm it’s live."
        puts "Press ENTER when ready to continue..."
        $stdin.gets

        challenge.request_validation

        while challenge.status == "pending"
          puts "⏳ Waiting for DNS validation for #{domain}..."
          sleep 5
          challenge.reload
        end

        unless challenge.status == "valid"
          puts "❌ DNS validation failed for #{domain}. Status: #{challenge.status}"
          exit(1)
        end

        puts "✅ Domain #{domain} successfully verified!"
      end
    end

    def finalize_certificate
      @certificate_key = OpenSSL::PKey::RSA.new(4096)
      csr = Acme::Client::CertificateRequest.new(private_key: @certificate_key, names: @domains)
      @order.finalize(csr: csr)

      while @order.status == "processing"
        sleep 1
        @order.reload
      end

      return if @order.status == "valid"

      puts "❌ Failed to finalize order. Status: #{@order.status}"
      exit(1)
    end

    def save_certificate_files
      key_path = File.join(@output_dir, "private_key.pem")
      crt_path = File.join(@output_dir, "certificate.crt")
      ca_path = File.join(@output_dir, "ca_bundle.pem")

      File.write(key_path, @certificate_key.to_pem)
      File.write(crt_path, @order.certificate)
      File.write(ca_path, @order.certificate) # Optional

      zip_path = File.join(@output_dir, "cert_bundle.zip")
      create_zip(zip_path, [key_path, crt_path, ca_path])
    end

    def create_zip(zip_path, files)
      ::Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        files.each do |file|
          zipfile.add(File.basename(file), file) if File.exist?(file)
        end
      end
    end

    def notify_user
      puts "\n🎉 SSL certificate generated successfully for #{@domains.join(", ")}"
      puts "📁 Files saved in: #{@output_dir}"
      puts "- certificate.crt"
      puts "- private_key.pem"
      puts "- ca_bundle.pem"
      puts "\n🧾 You can now manually upload these files to your cPanel SSL/TLS section."
    end
  end
end
