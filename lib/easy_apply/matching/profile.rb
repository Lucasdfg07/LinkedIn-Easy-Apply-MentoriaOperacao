# frozen_string_literal: true

module EasyApply
  module Matching
    class Profile
      attr_reader :data

      def initialize(profile_data)
        @data = profile_data
      end

      def skills
        @skills ||= (data['skills'] || []).map { |s| s.to_s.downcase.strip }
      end

      def years_of_experience
        data.dig('experience', 'years') || 0
      end

      def education_degree
        data.dig('education', 'degree')&.downcase&.strip
      end

      def first_name
        data.dig('personal', 'first_name')
      end

      def last_name
        data.dig('personal', 'last_name')
      end

      def email
        data.dig('personal', 'email')
      end

      def phone
        data.dig('personal', 'phone')
      end

      def city
        data.dig('personal', 'city')
      end

      def easy_apply_answers
        data['easy_apply_answers'] || {}
      end

      def languages
        data['languages'] || []
      end

      def current_title
        data.dig('experience', 'current_title')
      end
    end
  end
end
