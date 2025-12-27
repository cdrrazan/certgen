# frozen_string_literal: true

RSpec.describe Certgen::CLI do
  describe ".start" do
    let(:generator) { instance_double(Certgen::Generator) }

    before do
      allow(Certgen::Generator).to receive(:new).and_return(generator)
      allow(generator).to receive(:run)
      
      # Silence all output streams to keep RSpec output clean
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)
      allow($stderr).to receive(:puts)
      allow($stderr).to receive(:print)
      
      # Stub abort on the CLI class specifically to prevent it from printing to stderr
      # and ensure it raises SystemExit with failure status (1) as expected.
      allow(Certgen::CLI).to receive(:abort) do |msg|
        # In Ruby, abort(msg) behaves like $stderr.puts(msg); exit(1)
        raise SystemExit.new(1)
      end
    end

    context "with valid 'generate' command" do
      let(:argv) { ["generate", "--domain", "example.com", "--email", "user@example.com"] }

      it "successfully routes to the generator" do
        expect { Certgen::CLI.start(argv) }.not_to raise_error
        expect(Certgen::Generator).to have_received(:new).with(
          domain: "example.com",
          email: "user@example.com",
          staging: false
        )
      end
    end

    context "with 'test' command (staging)" do
      let(:argv) { ["test", "-d", "example.org", "-e", "test@example.org"] }

      it "routes to the generator with staging enabled" do
        Certgen::CLI.start(argv)
        expect(Certgen::Generator).to have_received(:new).with(
          domain: "example.org",
          email: "test@example.org",
          staging: true
        )
      end
    end

    context "with unknown command" do
      let(:argv) { ["unknown"] }

      it "aborts with an error message" do
        expect { Certgen::CLI.start(argv) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context "with missing flags" do
      let(:argv) { ["generate", "--domain", "example.com"] }

      it "aborts due to missing email" do
        expect { Certgen::CLI.start(argv) }.to raise_error(SystemExit)
      end
    end

    context "with global flags" do
      it "displays the version and exits" do
        expect { Certgen::CLI.start(["-v"]) }.to raise_error(SystemExit)
      end
    end
  end
end
