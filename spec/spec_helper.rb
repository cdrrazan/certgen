# frozen_string_literal: true

# ---
# RSpec Configuration Bootstrapper
# This file initializes the testing environment and global lifecycle hooks.
# ---

# We load the core application namespace before any standard library mocks.
require_relative '../lib/certgen'

RSpec.configure do |config|
  # Expectation Configuration: Defines the preferred assertion syntax.
  config.expect_with :rspec do |expectations|
    # Enables chainable matcher descriptions for better failure readability.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Mocking Configuration: Defines how we handle test doubles.
  config.mock_with :rspec do |mocks|
    # Guard against stubbing non-existent methods (Verifying Partial Doubles).
    # This keeps our mocks in sync with real object interfaces.
    mocks.verify_partial_doubles = true
  end

  # Metadata Configuration: Controls context inheritance.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Suggested RSpec best practices for local development and CI:
  
  # Allow focusing specific tests via 'fit', 'fdescribe', etc.
  config.filter_run_when_matching :focus

  # Randomize execution order to uncover hidden state dependencies.
  config.order = :random

  # Print the 10 slowest examples to help audit test performance.
  config.profile_examples = 10
end
