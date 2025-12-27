# frozen_string_literal: true

require 'acme-client'

RSpec.describe Certgen::Generator do
  let(:domain) { 'example.com' }
  let(:email) { 'user@example.com' }
  let(:generator) { Certgen::Generator.new(domain: domain, email: email, staging: true) }

  # Stub external dependencies
  let(:acme_client) { instance_double(Acme::Client) }
  let(:acme_order) { instance_double(Acme::Client::Resources::Order) }
  let(:acme_auth) { instance_double(Acme::Client::Resources::Authorization) }
  let(:acme_challenge) { instance_double(Acme::Client::Resources::Challenges::DNS01) }

  before do
    # Prevent real file system writes and directory removals
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:rm_rf)
    allow(File).to receive(:write)
    allow(File).to receive(:exist?).and_return(false)
    allow(Dir).to receive(:exist?).and_return(false)

    # Stub ACME Client interactions
    allow(Acme::Client).to receive(:new).and_return(acme_client)
    allow(acme_client).to receive(:new_account)
    allow(acme_client).to receive(:new_order).and_return(acme_order)

    # Stub Order interactions
    allow(acme_order).to receive(:authorizations).and_return([acme_auth])
    allow(acme_order).to receive(:finalize)
    allow(acme_order).to receive(:status).and_return('valid')
    allow(acme_order).to receive(:certificate).and_return('STUB_CERT')

    # Stub Auth/Challenge interactions
    allow(acme_auth).to receive(:identifier).and_return({ 'value' => 'example.com' })
    allow(acme_auth).to receive(:dns).and_return(acme_challenge)
    allow(acme_challenge).to receive(:record_content).and_return('CHALLENGE_VALUE')
    allow(acme_challenge).to receive(:request_validation)
    allow(acme_challenge).to receive(:status).and_return('valid')
    allow(acme_challenge).to receive(:reload)

    # Prevent progress output from cluttering test results
    allow(generator).to receive(:puts)
    allow(generator).to receive(:print)

    # Stub user input
    allow($stdin).to receive(:gets).and_return("\n")
  end

  describe '#run' do
    it 'executes the full ACME workflow successfully' do
      expect { generator.run }.not_to raise_error

      expect(Acme::Client).to have_received(:new)
      expect(acme_client).to have_received(:new_order)
      expect(acme_challenge).to have_received(:request_validation)
      expect(acme_order).to have_received(:finalize)
    end

    it 'raises a Certgen::Error when a step fails' do
      allow(acme_order).to receive(:status).and_return('invalid')

      expect { generator.run }.to raise_error(Certgen::Error, /Order finalization failed/)
    end
  end

  describe 'Initialization' do
    it 'sets up the correct directory URLs' do
      prod_gen = Certgen::Generator.new(domain: domain, email: email, staging: false)
      expect(prod_gen.instance_variable_get(:@directory_url)).to eq(Certgen::Generator::LETS_ENCRYPT_PRODUCTION)

      stage_gen = Certgen::Generator.new(domain: domain, email: email, staging: true)
      expect(stage_gen.instance_variable_get(:@directory_url)).to eq(Certgen::Generator::LETS_ENCRYPT_STAGING)
    end

    it 'automatically adds www subdomain' do
      expect(generator.instance_variable_get(:@domains)).to include('example.com', 'www.example.com')
    end
  end
end
