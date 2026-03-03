# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyApply::Matching::Scorer do
  let(:config) do
    {
      'matching' => {
        'threshold' => 0.70,
        'weights' => { 'skills' => 0.60, 'experience' => 0.25, 'education' => 0.15 }
      }
    }
  end

  let(:profile) do
    EasyApply::Matching::Profile.new(
      'skills' => %w[ruby rails javascript postgresql docker],
      'experience' => { 'years' => 5 },
      'education' => { 'degree' => 'bachelor' }
    )
  end

  subject { described_class.new(config) }

  describe '#score' do
    it 'returns perfect score when all requirements match' do
      requirements = {
        skills: %w[ruby rails javascript],
        years_required: 3,
        education_required: 'bachelor'
      }

      result = subject.score(profile, requirements)
      expect(result[:total]).to eq(1.0)
      expect(result[:pass]).to be true
    end

    it 'returns partial score for partial skill match' do
      requirements = {
        skills: %w[ruby rails python go],
        years_required: 5,
        education_required: 'bachelor'
      }

      result = subject.score(profile, requirements)
      # skill: 2/4 = 0.5, exp: 1.0, edu: 1.0
      # 0.60*0.5 + 0.25*1.0 + 0.15*1.0 = 0.30 + 0.25 + 0.15 = 0.70
      expect(result[:total]).to eq(0.7)
      expect(result[:pass]).to be true
    end

    it 'fails when score below threshold' do
      requirements = {
        skills: %w[python go rust elixir scala],
        years_required: 10,
        education_required: 'phd'
      }

      result = subject.score(profile, requirements)
      expect(result[:pass]).to be false
    end

    it 'gives full score when no requirements mentioned' do
      requirements = {
        skills: [],
        years_required: nil,
        education_required: nil
      }

      result = subject.score(profile, requirements)
      expect(result[:total]).to eq(1.0)
      expect(result[:pass]).to be true
    end

    it 'gives 0.7 experience score when 1 year short' do
      requirements = {
        skills: %w[ruby],
        years_required: 6,
        education_required: nil
      }

      result = subject.score(profile, requirements)
      expect(result.dig(:breakdown, :experience, :score)).to eq(0.7)
    end

    it 'gives 0.3 experience score when more than 1 year short' do
      requirements = {
        skills: %w[ruby],
        years_required: 10,
        education_required: nil
      }

      result = subject.score(profile, requirements)
      expect(result.dig(:breakdown, :experience, :score)).to eq(0.3)
    end

    it 'includes matched skills in breakdown' do
      requirements = {
        skills: %w[ruby python rails],
        years_required: nil,
        education_required: nil
      }

      result = subject.score(profile, requirements)
      expect(result.dig(:breakdown, :skills, :matched)).to contain_exactly('ruby', 'rails')
    end
  end
end
