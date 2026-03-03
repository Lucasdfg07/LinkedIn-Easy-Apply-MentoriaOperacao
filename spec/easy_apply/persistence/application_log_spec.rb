# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe EasyApply::Persistence::ApplicationLog do
  around do |example|
    Dir.mktmpdir do |dir|
      @path = File.join(dir, 'applications_log.json')
      example.run
    end
  end

  subject { described_class.new(path: @path) }

  let(:job) { { id: '123', title: 'Ruby Dev', company: 'Acme', location: 'Remote' } }
  let(:score) do
    {
      total: 0.85,
      pass: true,
      breakdown: {
        skills: { score: 0.8 },
        experience: { score: 1.0 },
        education: { score: 1.0 }
      }
    }
  end

  describe '#log_decision!' do
    it 'appends an entry' do
      subject.log_decision!(job: job, score: score, decision: 'applied', result: 'success')
      expect(subject.entries.size).to eq(1)
      expect(subject.entries.first['decision']).to eq('applied')
    end

    it 'persists across instances' do
      subject.log_decision!(job: job, score: score, decision: 'skipped')

      new_log = described_class.new(path: @path)
      expect(new_log.entries.size).to eq(1)
    end
  end

  describe '#stats' do
    it 'computes stats correctly' do
      subject.log_decision!(job: job, score: score, decision: 'applied')
      subject.log_decision!(job: job, score: { **score, total: 0.5 }, decision: 'skipped')

      stats = subject.stats
      expect(stats[:total]).to eq(2)
      expect(stats[:applied]).to eq(1)
      expect(stats[:skipped]).to eq(1)
    end
  end

  describe '#recent' do
    it 'returns last N entries' do
      3.times { |i| subject.log_decision!(job: { **job, id: i.to_s }, score: score, decision: 'applied') }
      expect(subject.recent(2).size).to eq(2)
    end
  end
end
