# frozen_string_literal: true

RSpec.describe Certgen do
  it "has a version number" do
    expect(Certgen::VERSION).not_to be nil
  end

  describe ".generate" do
    let(:domain) { "example.com" }
    let(:email) { "user@example.com" }
    let(:generator) { instance_double(Certgen::Generator) }

    before do
      allow(Certgen::Generator).to receive(:new).with(domain: domain, email: email).and_return(generator)
      allow(generator).to receive(:run)
    end

    it "instantiates a generator and calls run" do
      Certgen.generate(domain: domain, email: email)
      expect(generator).to have_received(:run)
    end
  end
end
