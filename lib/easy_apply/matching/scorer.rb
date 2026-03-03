# frozen_string_literal: true

module EasyApply
  module Matching
    class Scorer
      EDUCATION_HIERARCHY = RequirementExtractor::EDUCATION_HIERARCHY

      def initialize(config)
        weights = config.dig('matching', 'weights')
        @skill_weight = weights['skills'] || 0.60
        @experience_weight = weights['experience'] || 0.25
        @education_weight = weights['education'] || 0.15
        @threshold = config.dig('matching', 'threshold') || 0.70
      end

      def score(profile, requirements)
        skill_score = calculate_skill_score(profile.skills, requirements[:skills])
        exp_score = calculate_experience_score(profile.years_of_experience, requirements[:years_required])
        edu_score = calculate_education_score(profile.education_degree, requirements[:education_required])

        total = (@skill_weight * skill_score) +
                (@experience_weight * exp_score) +
                (@education_weight * edu_score)

        {
          total: total.round(3),
          pass: total >= @threshold,
          threshold: @threshold,
          breakdown: {
            skills: { score: skill_score.round(3), weight: @skill_weight,
                      matched: matched_skills(profile.skills, requirements[:skills]),
                      required: requirements[:skills] },
            experience: { score: exp_score.round(3), weight: @experience_weight,
                          profile_years: profile.years_of_experience,
                          required_years: requirements[:years_required] },
            education: { score: edu_score.round(3), weight: @education_weight,
                         profile_degree: profile.education_degree,
                         required_degree: requirements[:education_required] }
          }
        }
      end

      private

      def calculate_skill_score(profile_skills, required_skills)
        return 1.0 if required_skills.nil? || required_skills.empty?

        matched = matched_skills(profile_skills, required_skills)
        matched.size.to_f / required_skills.size
      end

      def matched_skills(profile_skills, required_skills)
        return [] if required_skills.nil? || required_skills.empty?

        required_skills.select { |s| profile_skills.include?(s) }
      end

      def calculate_experience_score(profile_years, required_years)
        return 1.0 if required_years.nil?

        diff = profile_years - required_years

        if diff >= 0
          1.0
        elsif diff >= -1
          0.7
        else
          0.3
        end
      end

      def calculate_education_score(profile_degree, required_degree)
        return 1.0 if required_degree.nil?
        return 0.3 if profile_degree.nil?

        profile_idx = EDUCATION_HIERARCHY.index(profile_degree) || 0
        required_idx = EDUCATION_HIERARCHY.index(required_degree) || 0

        profile_idx >= required_idx ? 1.0 : 0.5
      end
    end
  end
end
