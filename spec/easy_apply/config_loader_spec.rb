# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'yaml'

RSpec.describe EasyApply::ConfigLoader do
  let(:valid_config) do
    {
      'linkedin' => { 'li_at' => 'abc123' },
      'search' => { 'keywords' => 'Ruby', 'location' => 'Brazil', 'easy_apply_only' => true },
      'matching' => { 'threshold' => 0.70, 'weights' => { 'skills' => 0.60, 'experience' => 0.25, 'education' => 0.15 } },
      'polling' => { 'interval_seconds' => 60, 'max_applications_per_session' => 50, 'break_after_applications' => 7, 'break_duration_seconds_min' => 120, 'break_duration_seconds_max' => 300 },
      'delays' => { 'between_actions_min' => 0.8, 'between_actions_max' => 2.5, 'between_applications_min' => 15, 'between_applications_max' => 45, 'typing_delay_min_ms' => 50, 'typing_delay_max_ms' => 200 },
      'browser' => { 'headless' => false, 'window_width_min' => 1200, 'window_width_max' => 1400, 'window_height_min' => 800, 'window_height_max' => 1000 }
    }
  end

  let(:valid_profile) do
    {
      'personal' => { 'first_name' => 'John', 'last_name' => 'Doe', 'email' => 'john@example.com' },
      'experience' => { 'years' => 5, 'current_title' => 'Senior Developer' },
      'education' => { 'degree' => 'bachelor' },
      'skills' => %w[ruby rails javascript]
    }
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @config_path = File.join(dir, 'config.yml')
      @profile_path = File.join(dir, 'profile.yml')
      File.write(@config_path, YAML.dump(valid_config))
      File.write(@profile_path, YAML.dump(valid_profile))
      example.run
    end
  end

  subject { described_class.new(config_path: @config_path, profile_path: @profile_path) }

  describe '#load!' do
    it 'loads config and profile successfully' do
      subject.load!
      expect(subject.config).to be_a(Hash)
      expect(subject.profile).to be_a(Hash)
    end

    it 'raises on missing config file' do
      loader = described_class.new(config_path: '/nonexistent.yml', profile_path: @profile_path)
      expect { loader.load! }.to raise_error(EasyApply::ConfigError, /not found/)
    end

    it 'raises on missing required config keys' do
      File.write(@config_path, YAML.dump({ 'linkedin' => {} }))
      expect { subject.load! }.to raise_error(EasyApply::ConfigError, /Missing config keys/)
    end
  end

  describe '#validate!' do
    before { subject.load! }

    it 'returns no errors for valid config' do
      expect(subject.validate!).to be_empty
    end

    it 'detects placeholder li_at' do
      valid_config['linkedin']['li_at'] = 'YOUR_LI_AT_COOKIE_HERE'
      File.write(@config_path, YAML.dump(valid_config))
      subject.load!
      errors = subject.validate!
      expect(errors).to include(match(/li_at is not configured/))
    end

    it 'detects invalid threshold' do
      valid_config['matching']['threshold'] = 1.5
      File.write(@config_path, YAML.dump(valid_config))
      subject.load!
      errors = subject.validate!
      expect(errors).to include(match(/threshold must be between/))
    end
  end
end
