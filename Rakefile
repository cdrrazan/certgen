# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

# RSpec task for running tests
RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

# RuboCop task for code style checking
RuboCop::RakeTask.new

# Default task runs both tests and linting
task default: %i[spec rubocop]
