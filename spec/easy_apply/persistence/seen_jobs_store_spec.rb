# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe EasyApply::Persistence::SeenJobsStore do
  around do |example|
    Dir.mktmpdir do |dir|
      @path = File.join(dir, 'seen_jobs.json')
      example.run
    end
  end

  subject { described_class.new(path: @path) }

  describe '#seen? and #mark_seen!' do
    it 'tracks seen jobs' do
      expect(subject.seen?('123')).to be false

      subject.mark_seen!('123', title: 'Dev')
      expect(subject.seen?('123')).to be true
    end

    it 'persists across instances' do
      subject.mark_seen!('456', title: 'QA')

      new_store = described_class.new(path: @path)
      expect(new_store.seen?('456')).to be true
    end
  end

  describe '#count' do
    it 'returns the number of seen jobs' do
      subject.mark_seen!('1')
      subject.mark_seen!('2')
      expect(subject.count).to eq(2)
    end
  end

  describe '#clear!' do
    it 'resets the store' do
      subject.mark_seen!('1')
      subject.clear!
      expect(subject.count).to eq(0)
    end
  end
end
