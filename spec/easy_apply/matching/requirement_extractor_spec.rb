# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyApply::Matching::RequirementExtractor do
  subject { described_class.new }

  describe '#extract' do
    context 'skills extraction' do
      it 'extracts common tech skills' do
        desc = 'We need someone with Ruby on Rails, PostgreSQL, and Docker experience'
        result = subject.extract(desc)
        expect(result[:skills]).to include('rails', 'postgresql', 'docker')
      end

      it 'handles aliases' do
        desc = 'Experience with RoR, Node.js, and React.js required'
        result = subject.extract(desc)
        expect(result[:skills]).to include('rails', 'nodejs', 'react')
      end

      it 'returns empty for no matches' do
        result = subject.extract('Looking for a team player')
        expect(result[:skills]).to be_empty
      end

      it 'is case insensitive' do
        result = subject.extract('PYTHON and JAVASCRIPT developer')
        expect(result[:skills]).to include('python', 'javascript')
      end
    end

    context 'experience extraction' do
      it 'extracts years of experience' do
        result = subject.extract('5+ years of experience required')
        expect(result[:years_required]).to eq(5)
      end

      it 'extracts minimum years' do
        result = subject.extract('minimum of 3 years working with Ruby')
        expect(result[:years_required]).to eq(3)
      end

      it 'extracts "at least" pattern' do
        result = subject.extract('at least 7 years of experience')
        expect(result[:years_required]).to eq(7)
      end

      it 'returns nil when not mentioned' do
        result = subject.extract('Looking for a Ruby developer')
        expect(result[:years_required]).to be_nil
      end
    end

    context 'education extraction' do
      it 'extracts bachelor degree' do
        result = subject.extract("Bachelor's degree in Computer Science")
        expect(result[:education_required]).to eq('bachelor')
      end

      it 'extracts master degree' do
        result = subject.extract('MSc or Masters in a related field')
        expect(result[:education_required]).to eq('master')
      end

      it 'returns nil when not mentioned' do
        result = subject.extract('We value practical skills and teamwork')
        expect(result[:education_required]).to be_nil
      end
    end
  end
end
