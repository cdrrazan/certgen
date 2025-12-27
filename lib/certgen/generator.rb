# frozen_string_literal: true

require "acme-client"
require "fileutils"
require "openssl"
require "zip"

module Certgen
  # Generator: Core implementation of the ACME (Automated Certificate Management Environment) protocol.
  #
  # This class orchestrates the complex dance of SSL certificate issuance:
  # 1. ACME Account Management (registration/re-authentication)
  # 2. Domain Authorization (DNS-01 challenge orchestration)
  # 3. Order Finalization (CSR generation and signing)
  # 4. Artifact Management (Key and Certificate persistence)
  #
  # It targets Let's Encrypt specifically but follows standard ACME v2 patterns.
  class Generator
    # Production directory URL for Let's Encrypt.
    LETS_ENCRYPT_PRODUCTION = "https://acme-v02.api.letsencrypt.org/directory"
    # Staging directory URL (safer for testing/debugging to avoid rate limits).
    LETS_ENCRYPT_STAGING    = "https://acme-staging-v02.api.letsencrypt.org/directory"

    # Default path for the persistent ACME account key.
    # Reusing this key across runs is a best practice to keep a consistent ACME identity.
    ACCOUNT_KEY_PATH = File.expand_path("~/.certgen/acme_account.key")

    # @param domain [String] The apex or subdomain to secure.
    # @param email [String] The email used to register or identify the ACME account.
    # @param staging [Boolean] If true, uses the Let's Encrypt staging environment.
    def initialize(domain:, email:, staging: false)
      @input_domain  = domain
      @email         = email
      @staging       = staging
      @directory_url = staging ? LETS_ENCRYPT_STAGING : LETS_ENCRYPT_PRODUCTION
      
      # Handle 'www' normalization. We issue for both apex and www by default.
      @base_domain   = domain.sub(/^www\./, "")
      @domains       = [@base_domain, "www.#{@base_domain}"].uniq
      
      # Directory where generated certificates and keys will be stored.
      @output_dir    = File.expand_path("~/.ssl_output/#{@base_domain}")
    end

    # Orchestrates the full lifecycle of certificate generation.
    # Entry point for the generator logic.
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
      raise Certgen::Error, "Generation failed: #{e.message}"
    end

    private

    # Retrieves or generates the primary ACME account key (RSA 4096).
    # This key identifies the user to Let's Encrypt.
    def ensure_account_key!
      FileUtils.mkdir_p(File.dirname(ACCOUNT_KEY_PATH))
      
      if File.exist?(ACCOUNT_KEY_PATH)
        puts "🔐 Loading existing ACME account key..."
        @account_key = OpenSSL::PKey::RSA.new(File.read(ACCOUNT_KEY_PATH))
      else
        puts "🛠 Generating new ACME account key (RSA 4096)..."
        @account_key = OpenSSL::PKey::RSA.new(4096)
        File.write(ACCOUNT_KEY_PATH, @account_key.to_pem)
      end
    end

    # Initializes the ACME client and handles account registration.
    # Registration is idempotent; if the account exists, we move forward.
    def setup_client
      @client = Acme::Client.new(
        private_key: @account_key,
        directory: @directory_url
      )

      begin
        @client.new_account(contact: "mailto:#{@email}", terms_of_service_agreed: true)
      rescue Acme::Client::Error::Malformed => e
        # Often means the account is already registered for this key
        puts "ℹ️  ACME account session established."
      end
    end

    # Prepares the target storage location.
    # Note: Currently wipes previous output for the same domain to ensure no stale artifacts.
    def create_output_directory
      if Dir.exist?(@output_dir)
        puts "🧹 Preparing output directory: #{@output_dir}"
        FileUtils.rm_rf(@output_dir)
      end
      FileUtils.mkdir_p(@output_dir)
    end

    # Initiates a new ACME Order for the specified domain set.
    def order_certificate
      puts "📦 Creating new certificate order..."
      @order = @client.new_order(identifiers: @domains)
      @authorizations = @order.authorizations
    end

    # Iterates through required authorizations and prompts for DNS-01 verification.
    # This is the manual step where the user must modify their DNS records.
    def verify_dns_challenges
      @authorizations.each do |auth|
        domain = auth.identifier["value"]
        challenge = auth.dns

        puts "\n" + ("=" * 60)
        puts "🔑 DNS-01 CHALLENGE REQUIRED: #{domain}"
        puts ("=" * 60)
        puts "Type:  TXT"
        puts "Host:  _acme-challenge.#{domain}"
        puts "Value: #{challenge.record_content}"
        puts ("=" * 60)
        puts "\n👉 Please create the TXT record above in your DNS provider."
        puts "⏳ Propagation can take several minutes (check via dnschecker.org)."
        puts "⌨️  Press ENTER when you are confident the record is live..."
        
        $stdin.gets

        challenge.request_validation

        # Polling loop for challenge status
        while challenge.status == "pending"
          print "."
          sleep 5
          challenge.reload
        end
        puts "\n"

        unless challenge.status == "valid"
          raise Certgen::Error, "DNS validation failed for #{domain} (Status: #{challenge.status})"
        end

        puts "✅ Domain #{domain} successfully authorized!"
      end
    end

    # Finalizes the order by generating a new Certificate Signing Request (CSR).
    # The certificate key generated here is DIFFERENT from the account key.
    def finalize_certificate
      puts "📝 Generating CSR and finalising order..."
      
      # We generate a fresh 4096-bit RSA key for the actual certificate
      @certificate_key = OpenSSL::PKey::RSA.new(4096)
      
      # Build the CSR with the requested domains
      csr = Acme::Client::CertificateRequest.new(
        private_key: @certificate_key, 
        names: @domains
      )
      
      @order.finalize(csr: csr)

      # Wait for the CA to process the request and issue the cert
      while @order.status == "processing"
        sleep 2
        @order.reload
      end

      unless @order.status == "valid"
        raise Certgen::Error, "Order finalization failed (Status: #{@order.status})"
      end
    end

    # Writes the resulting cryptographic artifacts to the filesystem.
    def save_certificate_files
      key_path = File.join(@output_dir, "private_key.pem")
      crt_path = File.join(@output_dir, "certificate.crt")
      ca_path  = File.join(@output_dir, "ca_bundle.pem")

      # Write individual PEM components
      File.write(key_path, @certificate_key.to_pem)
      File.write(crt_path, @order.certificate) # Contains the full chain
      File.write(ca_path, @order.certificate)  # Mirroring for compatibility

      # Create a convenient ZIP bundle for download/transfer
      zip_path = File.join(@output_dir, "cert_bundle.zip")
      create_zip(zip_path, [key_path, crt_path, ca_path])
    end

    # Compresses multiple files into a single ZIP archive.
    # Uses the 'rubyzip' gem.
    #
    # @param zip_path [String] Output path for the zip file.
    # @param files [Array<String>] List of absolute file paths to include.
    def create_zip(zip_path, files)
      ::Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        files.each do |file|
          next unless File.exist?(file)
          zipfile.add(File.basename(file), file)
        end
      end
    end

    # Final user notification with path details.
    def notify_user
      puts "\n" + ("🎉" * 20)
      puts "SSL CERTIFICATE SUCCESSFULLY ISSUED"
      puts ("🎉" * 20)
      puts "📍 Path:   #{@output_dir}"
      puts "🎁 Bundle: cert_bundle.zip"
      puts "\nInstructions:"
      puts "1. Extract the bundle."
      puts "2. Upload 'certificate.crt' and 'private_key.pem' to your server/cPanel."
      puts "3. Don't forget to keep your account key safe!"
      puts ("=" * 40)
    end
  end
end
