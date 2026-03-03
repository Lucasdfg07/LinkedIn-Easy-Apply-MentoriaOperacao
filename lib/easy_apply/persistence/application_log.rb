# frozen_string_literal: true

require 'json'
require 'fileutils'

module EasyApply
  module Persistence
    class ApplicationLog
      DEFAULT_PATH = 'data/applications_log.json'

      def initialize(path: DEFAULT_PATH)
        @path = path
        @entries = load_log
      end

      def log_decision!(job:, score:, decision:, result: nil)
        entry = {
          'timestamp' => Time.now.iso8601,
          'job_id' => job[:id],
          'title' => job[:title],
          'company' => job[:company],
          'location' => job[:location],
          'score' => score[:total],
          'pass' => score[:pass],
          'decision' => decision,
          'result' => result,
          'breakdown' => {
            'skills' => score.dig(:breakdown, :skills, :score),
            'experience' => score.dig(:breakdown, :experience, :score),
            'education' => score.dig(:breakdown, :education, :score)
          }
        }

        @entries << entry
        save!
        entry
      end

      def stats
        total = @entries.size
        applied = @entries.count { |e| e['decision'] == 'applied' }
        skipped = @entries.count { |e| e['decision'] == 'skipped' }
        failed = @entries.count { |e| e['decision'] == 'failed' }

        {
          total: total,
          applied: applied,
          skipped: skipped,
          failed: failed,
          avg_score: total > 0 ? (@entries.sum { |e| e['score'].to_f } / total).round(3) : 0
        }
      end

      def recent(n = 10)
        @entries.last(n)
      end

      def entries
        @entries
      end

      private

      def load_log
        return [] unless File.exist?(@path)

        JSON.parse(File.read(@path))
      rescue JSON::ParserError => e
        Log.warn("Corrupt application log, starting fresh: #{e.message}")
        []
      end

      def save!
        FileUtils.mkdir_p(File.dirname(@path))
        File.write(@path, JSON.pretty_generate(@entries))
      end
    end
  end
end
