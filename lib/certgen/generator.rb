# frozen_string_literal: true

require 'acme-client'
require 'fileutils'
require 'openssl'
require 'zip'

module Certgen
  # Generator: Core implementation of the ACME (Automated Certificate Management Environment) protocol.
  #
  # This class orchestrates the complex dance of SSL certificate issuance:
  # 1. ACME Account Management: Identifies the user to Let's Encrypt using a persistent RSA key.
  # 2. Domain Authorization: Proves ownership of the domains via DNS-01 TXT record manual injection.
  # 3. Order Finalization: Generates a CSR and requests the CA to sign it.
  # 4. Artifact Management: Persists the resulting keys, certificates, and bundles for user deployment.
  #
  # It targets Let's Encrypt specifically but follows standard RFC 8555 (ACME) patterns.
  class Generator
    # Production directory URL for Let's Encrypt.
    LETS_ENCRYPT_PRODUCTION = 'https://acme-v02.api.letsencrypt.org/directory'
    # Staging directory URL - crucial for testing to avoid strict rate limits.
    LETS_ENCRYPT_STAGING = 'https://acme-staging-v02.api.letsencrypt.org/directory'

    # Default path for the persistent ACME account key.
    # We reuse this key to maintain a consistent identity with Let's Encrypt, which is
    # helpful for tracking rate limits and managing existing authorizations.
    ACCOUNT_KEY_PATH = File.expand_path('~/.certgen/acme_account.key')

    # @param domain [String] The apex or subdomain to secure.
    # @param email [String] The email used to register or identify the ACME account.
    # @param staging [Boolean] If true, uses the Let's Encrypt staging environment.
    def initialize(domain:, email:, staging: false)
      @input_domain = domain
      @email = email
      @staging = staging
      @directory_url = staging ? LETS_ENCRYPT_STAGING : LETS_ENCRYPT_PRODUCTION

      # ACME typically requires authorization for both apex and www subdomains unless using wildcards.
      # We normalize to both for maximum "out-of-the-box" compatibility for standard web hosting.
      @base_domain = domain.sub(/^www\./, '')
      @domains = [@base_domain, "www.#{@base_domain}"].uniq

      # Output artifacts are organized by the base domain to keep the home directory clean.
      @output_dir = File.expand_path("~/.ssl_output/#{@base_domain}")
    end

    # Orchestrates the full lifecycle of certificate generation.
    # This is the primary entry point for the business logic.
    #
    # @raise [Certgen::Error] if any step in the process fails.
    def run
      puts "🚀 Starting certificate generation for: #{@domains.join(', ')}"
      puts "🌐 Environment: #{@staging ? 'STAGING' : 'PRODUCTION'}"

      ensure_account_key!
      setup_client
      create_output_directory
      order_certificate
      verify_dns_challenges
      finalize_certificate
      save_certificate_files
      notify_user
    rescue StandardError => e
      # Wrap low-level or library errors in our domain-specific exception for cleaner CLI reporting.
      raise Certgen::Error, "Generation failed: #{e.message}"
    end

    private

    # Retrieves or generates the primary ACME account key (RSA 4096).
    # This key is NOT the certificate key; it is your identity for the ACME server.
    #
    # @return [void]
    def ensure_account_key!
      FileUtils.mkdir_p(File.dirname(ACCOUNT_KEY_PATH))

      if File.exist?(ACCOUNT_KEY_PATH)
        puts '🔐 Loading existing ACME account key...'
        @account_key = OpenSSL::PKey::RSA.new(File.read(ACCOUNT_KEY_PATH))
      else
        puts '🛠 Generating new ACME account key (RSA 4096)...'
        @account_key = OpenSSL::PKey::RSA.new(4096)
        File.write(ACCOUNT_KEY_PATH, @account_key.to_pem)
      end
    end

    # Initializes the ACME client and handles account registration.
    # Registration is idempotent; if the account already exists for the key, we move forward.
    #
    # @return [void]
    def setup_client
      @client = Acme::Client.new(
        private_key: @account_key,
        directory: @directory_url
      )

      begin
        @client.new_account(contact: "mailto:#{@email}", terms_of_service_agreed: true)
      rescue Acme::Client::Error::Malformed
        # ACME 201 Created vs 200 OK - library handles registration, so Malformed usually
        # implies the account is already associated with this key.
        puts 'ℹ️  ACME account session established.'
      end
    end

    # Prepares the target storage location.
    # We purge any existing directory to ensure we don't end up with mixed or stale cert files.
    #
    # @return [void]
    def create_output_directory
      if Dir.exist?(@output_dir)
        puts "🧹 Purging stale artifacts from: #{@output_dir}"
        FileUtils.rm_rf(@output_dir)
      end
      FileUtils.mkdir_p(@output_dir)
    end

    # Initiates a new ACME Order for the specified domain set.
    # The order status transitions from 'pending' as we fulfill authorizations.
    #
    # @return [void]
    def order_certificate
      puts '📦 Creating new certificate order...'
      @order = @client.new_order(identifiers: @domains)
      @authorizations = @order.authorizations
    end

    # Iterates through required authorizations and prompts for DNS-01 verification.
    # This remains the only manual step. DNS-01 is preferred over HTTP-01 as it
    # handles wildcard domains and doesn't require firewall modifications.
    #
    # @return [void]
    # @raise [Certgen::Error] if validation fails after polling.
    def verify_dns_challenges
      @authorizations.each do |auth|
        domain = auth.identifier['value']
        challenge = auth.dns

        puts "\n#{'=' * 60}"
        puts "🔑 ACTION REQUIRED: Update DNS for #{domain}"
        puts('=' * 60)
        puts 'Type:  TXT'
        puts "Host:  _acme-challenge.#{domain}"
        puts "Value: #{challenge.record_content}"
        puts('=' * 60)
        puts "\n👉 Please create the TXT record above in your DNS provider manager."
        puts '⏳ Global propagation can take time. Use https://dnschecker.org to audit.'
        puts '⌨️  Press [ENTER] only after you verify the record is publicly visible...'

        $stdin.gets

        # Tell Let's Encrypt to start checking the record
        challenge.request_validation

        # Polling loop: Active wait for status transition out of 'pending'
        while challenge.status == 'pending'
          print '.'
          sleep 5
          challenge.reload
        end
        puts "\n"

        unless challenge.status == 'valid'
          raise Certgen::Error, "DNS validation failed for #{domain} (Status: #{challenge.status})"
        end

        puts "✅ Domain #{domain} successfully authorized!"
      end
    end

    # Finalizes the order by generating a new Certificate Signing Request (CSR).
    # We generate a fresh RSA 4096 key for the certificate itself. This separation
    # of the Account Key and Certificate Key is a security best practice.
    #
    # @return [void]
    # @raise [Certgen::Error] if the order fails to transition to 'valid'.
    def finalize_certificate
      puts '📝 Finalizing order and generating CSR...'

      # Generate the actual private key that secures your web traffic.
      @certificate_key = OpenSSL::PKey::RSA.new(4096)

      # Construct the CSR containing the domains we verified.
      csr = Acme::Client::CertificateRequest.new(
        private_key: @certificate_key,
        names: @domains
      )

      @order.finalize(csr: csr)

      # Order processing usually takes a few seconds at Let's Encrypt.
      while @order.status == 'processing'
        sleep 2
        @order.reload
      end

      return if @order.status == 'valid'

      raise Certgen::Error, "Order finalization failed (Status: #{@order.status})"
    end

    # Persists the final cryptographic artifacts.
    # Most hosts (like cPanel) expect individual PEM files or a consolidated ZIP.
    #
    # @return [void]
    def save_certificate_files
      key_path = File.join(@output_dir, 'private_key.pem')
      crt_path = File.join(@output_dir, 'certificate.crt')
      ca_path = File.join(@output_dir, 'ca_bundle.pem')

      # Persistence Layer
      File.write(key_path, @certificate_key.to_pem)
      # @order.certificate typically contains the full chain (leaf + intermediate).
      File.write(crt_path, @order.certificate)
      # Mirroring the chain for CA Bundle compatibility on legacy platforms.
      File.write(ca_path, @order.certificate)

      # Bundling: Convenience package for easier upload/transfer.
      zip_path = File.join(@output_dir, 'cert_bundle.zip')
      create_zip(zip_path, [key_path, crt_path, ca_path])
    end

    # Utility method for cross-platform file compression.
    #
    # @param zip_path [String] Target filesystem path.
    # @param files [Array<String>] Paths of files to include.
    # @return [void]
    def create_zip(zip_path, files)
      ::Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        files.each do |file|
          next unless File.exist?(file)

          zipfile.add(File.basename(file), file)
        end
      end
    end

    # Provides the final success payload and instructions to the CLI user.
    #
    # @return [void]
    def notify_user
      puts "\n#{'🎉' * 20}"
      puts 'SSL CERTIFICATE SUCCESSFULLY ISSUED'
      puts('🎉' * 20)
      puts "📍 Path:   #{@output_dir}"
      puts '🎁 Bundle: cert_bundle.zip'
      puts "\nNext Steps:"
      puts '1. Download the cert_bundle.zip from the path above.'
      puts "2. In your hosting panel: upload 'certificate.crt' and 'private_key.pem'."
      puts '3. Keep your ACME account key secure for future renewals.'
      puts('=' * 40)
    end
  end
end
