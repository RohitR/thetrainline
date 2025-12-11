# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'spec_helper'
require 'date'
require_relative '../../lib/core/hourly_segment_selector'

RSpec.describe Core::HourlySegmentSelector do
  let(:segment) { Struct.new(:departure_at, :id) }

  describe '#call' do
    it 'groups segments by hour and returns one per hour starting at departure_at' do
      departure_at = DateTime.new(2025, 12, 10, 6, 0, 0)
      segments = [
        segment.new(DateTime.new(2025, 12, 10, 6, 5, 0), 's1'),
        segment.new(DateTime.new(2025, 12, 10, 6, 30, 0), 's2'),
        segment.new(DateTime.new(2025, 12, 10, 7, 10, 0), 's3'),
        segment.new(DateTime.new(2025, 12, 10, 8, 0, 0), 's4'),
        segment.new(DateTime.new(2025, 12, 10, 9, 0, 0), 's5')
      ]

      selector = described_class.new(segments: segments, departure_at: departure_at, limit: 3)
      picked = selector.call

      expect(picked.size).to eq(3)
      expect(picked.map { |s| s.departure_at.hour }).to eq([6, 7, 8])
    end

    it 'fills remaining slots with earliest journeys when not enough distinct hours' do
      departure_at = DateTime.new(2025, 12, 10, 6, 0, 0)
      segments = [
        segment.new(DateTime.new(2025, 12, 10, 6, 5, 0), 'a'),
        segment.new(DateTime.new(2025, 12, 10, 6, 10, 0), 'b'),
        segment.new(DateTime.new(2025, 12, 10, 6, 20, 0), 'c'),
        segment.new(DateTime.new(2025, 12, 10, 9, 0, 0), 'd')
      ]

      selector = described_class.new(segments: segments, departure_at: departure_at, limit: 3)
      picked = selector.call

      expect(picked.size).to eq(3)
      expected_times = [
        DateTime.new(2025, 12, 10, 6, 5, 0),
        DateTime.new(2025, 12, 10, 9, 0, 0),
        DateTime.new(2025, 12, 10, 6, 10, 0)
      ]
      expect(picked.map(&:departure_at).sort).to eq(expected_times.sort)
    end

    it 'respects the provided limit' do
      departure_at = DateTime.new(2025, 12, 10, 6, 0, 0)
      segments = (0..10).map do |i|
        segment.new(DateTime.new(2025, 12, 10, 6 + (i / 2), i * 3 % 60, 0), "seg#{i}")
      end

      selector = described_class.new(segments: segments, departure_at: departure_at, limit: 2)
      picked = selector.call

      expect(picked.size).to eq(2)
    end
  end
end
# rubocop:enable Metrics/BlockLength
