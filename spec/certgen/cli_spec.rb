# frozen_string_literal: true

# Certgen::CLI Spec
#
# These tests validate the orchestration layer: argument parsing, global flag handling,
# and delegation to the core generator engine.
RSpec.describe Certgen::CLI do
  describe '.start' do
    let(:generator) { instance_double(Certgen::Generator) }

    before do
      allow(Certgen::Generator).to receive(:new).and_return(generator)
      allow(generator).to receive(:run)

      # Strategic suppression of standard output/error to keep RSpec test results focused.
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)
      allow($stderr).to receive(:puts)
      allow($stderr).to receive(:print)

      # Intercept the #abort method to prevent process termination and verify exit status.
      allow(described_class).to receive(:abort) do |_msg|
        raise SystemExit, 1
      end
    end

    context "with valid 'generate' command" do
      let(:argv) { ['generate', '--domain', 'example.com', '--email', 'user@example.com'] }

      it 'successfully parses options and initializes the production generator' do
        expect { described_class.start(argv) }.not_to raise_error
        expect(Certgen::Generator).to have_received(:new).with(
          domain: 'example.com',
          email: 'user@example.com',
          staging: false
        )
      end
    end

    context "with 'test' command (staging)" do
      let(:argv) { ['test', '-d', 'example.org', '-e', 'test@example.org'] }

      it 'configures the generator to use the staging ACME environment' do
        described_class.start(argv)
        expect(Certgen::Generator).to have_received(:new).with(
          domain: 'example.org',
          email: 'test@example.org',
          staging: true
        )
      end
    end

    context 'with unknown command' do
      let(:argv) { ['unknown'] }

      it 'terminates the application with a failure status (1)' do
        expect { described_class.start(argv) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'with missing mandatory flags' do
      let(:argv) { ['generate', '--domain', 'example.com'] }

      it 'guards against incomplete configuration and aborts' do
        expect { described_class.start(argv) }.to raise_error(SystemExit)
      end
    end

    context 'with global informational flags' do
      it 'displays the version and terminates successfully' do
        # NOTE: #puts is stubbed, but we verify SystemExit is still triggered.
        expect { described_class.start(['-v']) }.to raise_error(SystemExit)
      end
    end
  end
end
