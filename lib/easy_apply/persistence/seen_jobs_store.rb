# frozen_string_literal: true

require 'json'
require 'fileutils'

module EasyApply
  module Persistence
    class SeenJobsStore
      DEFAULT_PATH = 'data/seen_jobs.json'

      def initialize(path: DEFAULT_PATH)
        @path = path
        @seen = load_store
      end

      def seen?(job_id)
        @seen.key?(job_id.to_s)
      end

      def mark_seen!(job_id, metadata = {})
        @seen[job_id.to_s] = {
          'seen_at' => Time.now.iso8601,
          **metadata.transform_keys(&:to_s)
        }
        save!
      end

      def count
        @seen.size
      end

      def clear!
        @seen = {}
        save!
      end

      private

      def load_store
        return {} unless File.exist?(@path)

        JSON.parse(File.read(@path))
      rescue JSON::ParserError => e
        Log.warn("Corrupt seen_jobs store, resetting: #{e.message}")
        {}
      end

      def save!
        FileUtils.mkdir_p(File.dirname(@path))
        File.write(@path, JSON.pretty_generate(@seen))
      end
    end
  end
end
