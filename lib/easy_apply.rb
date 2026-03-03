# frozen_string_literal: true

require_relative 'easy_apply/logger'
require_relative 'easy_apply/config_loader'
require_relative 'easy_apply/anti_detection'
require_relative 'easy_apply/browser/wait_helpers'
require_relative 'easy_apply/browser/driver_factory'
require_relative 'easy_apply/browser/session'
require_relative 'easy_apply/linkedin/selectors'
require_relative 'easy_apply/linkedin/job_search'
require_relative 'easy_apply/linkedin/job_parser'
require_relative 'easy_apply/linkedin/easy_apply_flow'
require_relative 'easy_apply/matching/profile'
require_relative 'easy_apply/matching/requirement_extractor'
require_relative 'easy_apply/matching/scorer'
require_relative 'easy_apply/persistence/seen_jobs_store'
require_relative 'easy_apply/persistence/application_log'
require_relative 'easy_apply/cli'

module EasyApply
  VERSION = '1.0.0'

  class Error < StandardError; end
  class ConfigError < Error; end
  class SessionError < Error; end
  class BrowserError < Error; end
end
