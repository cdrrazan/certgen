# frozen_string_literal: true

# Certgen Module Spec
#
# Tests the high-level public API of the main Certgen namespace.
RSpec.describe Certgen do
  it 'provides a semantic version number' do
    expect(Certgen::VERSION).not_to be_nil
  end

  describe '.generate' do
    let(:domain) { 'example.com' }
    let(:email) { 'user@example.com' }
    let(:generator) { instance_double(Certgen::Generator) }

    before do
      # Programmatic entry point should delegate to the internal core engine.
      allow(Certgen::Generator).to receive(:new).with(domain: domain, email: email).and_return(generator)
      allow(generator).to receive(:run)
    end

    it 'orchestrates the generation process via the core Generator engine' do
      described_class.generate(domain: domain, email: email)
      expect(generator).to have_received(:run)
    end
  end
end
