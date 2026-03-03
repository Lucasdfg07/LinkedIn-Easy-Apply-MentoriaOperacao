# frozen_string_literal: true

require 'yaml'

module EasyApply
  class ConfigLoader
    REQUIRED_CONFIG_KEYS = %w[linkedin search matching polling delays browser].freeze
    REQUIRED_PROFILE_KEYS = %w[personal experience education skills].freeze

    attr_reader :config, :profile

    def initialize(config_path: 'config/config.yml', profile_path: 'config/profile.yml')
      @config_path = config_path
      @profile_path = profile_path
      @config = nil
      @profile = nil
    end

    def load!
      @config = load_yaml(@config_path, 'config')
      @profile = load_yaml(@profile_path, 'profile')
      validate_config!
      validate_profile!
      self
    end

    def validate!
      errors = []
      errors.concat(validate_config_structure)
      errors.concat(validate_profile_structure)
      errors.concat(validate_li_at)
      errors.concat(validate_thresholds)
      errors
    end

    private

    def load_yaml(path, label)
      raise ConfigError, "#{label} file not found: #{path}" unless File.exist?(path)

      YAML.safe_load(File.read(path), permitted_classes: [Symbol])
    rescue Psych::SyntaxError => e
      raise ConfigError, "Invalid YAML in #{label}: #{e.message}"
    end

    def validate_config!
      missing = REQUIRED_CONFIG_KEYS - @config.keys
      raise ConfigError, "Missing config keys: #{missing.join(', ')}" unless missing.empty?
    end

    def validate_profile!
      missing = REQUIRED_PROFILE_KEYS - @profile.keys
      raise ConfigError, "Missing profile keys: #{missing.join(', ')}" unless missing.empty?
    end

    def validate_config_structure
      errors = []
      missing = REQUIRED_CONFIG_KEYS - (@config&.keys || [])
      errors << "Missing config keys: #{missing.join(', ')}" unless missing.empty?
      errors
    end

    def validate_profile_structure
      errors = []
      missing = REQUIRED_PROFILE_KEYS - (@profile&.keys || [])
      errors << "Missing profile keys: #{missing.join(', ')}" unless missing.empty?
      errors
    end

    def validate_li_at
      errors = []
      li_at = @config&.dig('linkedin', 'li_at')
      if li_at.nil? || li_at == 'YOUR_LI_AT_COOKIE_HERE' || li_at.strip.empty?
        errors << 'linkedin.li_at is not configured'
      end
      errors
    end

    def validate_thresholds
      errors = []
      threshold = @config&.dig('matching', 'threshold')
      if threshold && (threshold < 0 || threshold > 1)
        errors << "matching.threshold must be between 0 and 1, got #{threshold}"
      end

      weights = @config&.dig('matching', 'weights')
      if weights
        sum = (weights['skills'] || 0) + (weights['experience'] || 0) + (weights['education'] || 0)
        errors << "matching.weights must sum to 1.0, got #{sum}" unless (sum - 1.0).abs < 0.01
      end
      errors
    end
  end
end
