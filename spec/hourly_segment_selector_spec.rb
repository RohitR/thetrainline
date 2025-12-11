# frozen_string_literal: true
require 'spec_helper'
require 'journey/hourly_segment_selector'
require "pry"

RSpec.describe Journey::HourlySegmentSelector do
  def build_segment_at(dt)
    Journey::Segment.new(
      departure_station: 'A',
      departure_at: dt,
      arrival_station: 'B',
      arrival_at: dt + Rational(2, 24),
      service_agencies: [],
      duration_in_minutes: 120,
      changeovers: 0,
      products: [],
      fares: []
    )
  end

  it 'selects at most one segment per hour starting from departure_at' do
    base = DateTime.new(2025, 12, 10, 6, 0, 0)
    segs = []
    # two segments in same hour, others in subsequent hours
    segs << build_segment_at(base + Rational(0, 24))
    segs << build_segment_at(base + Rational(0.2, 24)) # same hour
    (1..5).each { |h| segs << build_segment_at(base + Rational(h, 24)) }

    selector = Journey::HourlySegmentSelector.new(segments: segs, departure_at: base, limit: 4)
    chosen = selector.call
    expect(chosen.size).to eq(4)
    # first chosen should be earliest in the first hour
    expect(chosen.first.departure_at.hour).to eq(6)
    
    expect(chosen.map(&:departure_at).uniq.size).to eq(4)
  end

  it 'fills up with leftover segments if hourly scan did not reach limit' do
    base = DateTime.new(2025, 12, 10, 6, 0, 0)
    segs = []
    # only a single hour has segments
    segs << build_segment_at(base)
    segs << build_segment_at(base + Rational(0.1, 24))
    # leftovers later
    segs << build_segment_at(base + Rational(10, 24))
    segs << build_segment_at(base + Rational(20, 24))


    selector = Journey::HourlySegmentSelector.new(segments: segs, departure_at: base, limit: 4)
    chosen = selector.call
    expect(chosen.size).to eq(4)
  end
end