# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JourneySearch do
  let(:data_file) { File.expand_path('fixtures/journeys_sample.json', __dir__) }
  let(:client) { Clients::FileClient.new(file_path: data_file) }
  let(:departure_at) { DateTime.new(2025, 12, 10, 6, 10, 0) }
  subject do
    JourneySearch.new(from: 'Manchester Piccadilly', to: 'London Euston', departure_at: departure_at, client: client)
  end

  it 'returns 10 segments (one per hour starting at requested hour)' do
    results = subject.call
    expect(results).to be_an(Array)
    expect(results.size).to eq(10)
    hours = results.map { |s| s.departure_at.strftime('%Y-%m-%dT%H') }
    expect(hours).to eq(hours.sort)
  end

  it 'each element is a Segment and has fares' do
    results = subject.call
    expect(results.first).to be_a(Segment)
    expect(results.first.fares).not_to be_empty
    expect(results.first.to_h[:fares].first[:price_in_cents]).to be_a(Integer)
  end
end
