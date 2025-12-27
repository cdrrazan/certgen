# frozen_string_literal: true

require 'acme-client'

# Certgen::Generator Spec
#
# These tests focus on the orchestration logic of the ACME v2 protocol.
# We utilize deep mocking of the 'acme-client' resources to ensure we don't
# perform actual networking or file mutations during testing.
RSpec.describe Certgen::Generator do
  let(:domain) { 'example.com' }
  let(:email) { 'user@example.com' }
  let(:generator) { described_class.new(domain: domain, email: email, staging: true) }

  # --- Mocking Layer ---
  # These doubles represent the complex object graph returned by the ACME API.
  let(:acme_client) { instance_double(Acme::Client) }
  let(:acme_order) { instance_double(Acme::Client::Resources::Order) }
  let(:acme_auth) { instance_double(Acme::Client::Resources::Authorization) }
  let(:acme_challenge) { instance_double(Acme::Client::Resources::Challenges::DNS01) }

  before do
    # Global Guard: Prevent any real filesystem side-effects.
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:rm_rf)
    allow(File).to receive(:write)
    allow(File).to receive(:exist?).and_return(false)
    allow(Dir).to receive(:exist?).and_return(false)

    # ACME Client Setup
    allow(Acme::Client).to receive(:new).and_return(acme_client)
    allow(acme_client).to receive(:new_account)
    allow(acme_client).to receive(:new_order).and_return(acme_order)

    # Order State Management
    allow(acme_order).to receive(:finalize)
    allow(acme_order).to receive_messages(
      authorizations: [acme_auth],
      status: 'valid',
      certificate: 'STUB_CERT'
    )

    # Authorization & Challenge Lifecycle
    allow(acme_auth).to receive_messages(
      identifier: { 'value' => 'example.com' },
      dns: acme_challenge
    )
    allow(acme_challenge).to receive(:request_validation)
    allow(acme_challenge).to receive_messages(
      record_content: 'CHALLENGE_VALUE',
      status: 'valid'
    )
    allow(acme_challenge).to receive(:reload)

    # Output suppression to keep the RSpec progress reporter clean.
    allow(generator).to receive(:puts)
    allow(generator).to receive(:print)

    # Automatic interaction: Simulates the user pressing [ENTER] for DNS verification.
    allow($stdin).to receive(:gets).and_return("\n")
  end

  describe '#run' do
    it 'executes the full ACME workflow successfully' do
      expect { generator.run }.not_to raise_error

      # Verify that we hit all the critical protocol milestones.
      expect(Acme::Client).to have_received(:new)
      expect(acme_client).to have_received(:new_order)
      expect(acme_challenge).to have_received(:request_validation)
      expect(acme_order).to have_received(:finalize)
    end

    it 'raises a Certgen::Error when a protocol step fails' do
      # Simulate a transition to an 'invalid' order state (e.g., CA rejected CSR).
      allow(acme_order).to receive(:status).and_return('invalid')

      expect { generator.run }.to raise_error(Certgen::Error, /Order finalization failed/)
    end
  end

  describe 'Initialization' do
    it 'sets up the correct directory URLs based on the staging flag' do
      prod_gen = described_class.new(domain: domain, email: email, staging: false)
      expect(prod_gen.instance_variable_get(:@directory_url)).to eq(Certgen::Generator::LETS_ENCRYPT_PRODUCTION)

      stage_gen = described_class.new(domain: domain, email: email, staging: true)
      expect(stage_gen.instance_variable_get(:@directory_url)).to eq(Certgen::Generator::LETS_ENCRYPT_STAGING)
    end

    it 'automatically generates SANs (Subject Alternative Names) for apex and www' do
      expect(generator.instance_variable_get(:@domains)).to include('example.com', 'www.example.com')
    end
  end
end
