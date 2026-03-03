# frozen_string_literal: true

require_relative '../lib/easy_apply'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random

  # Suppress logger output during tests
  config.before(:suite) do
    EasyApply::Log.setup(log_dir: 'spec/tmp/log')
  end

  config.after(:suite) do
    FileUtils.rm_rf('spec/tmp')
  end
end
