# frozen_string_literal: true
require 'spec_helper'
require 'models/segment'


RSpec.describe Models::Segment do
  it 'parses different time types and returns a hash' do
    fare = Models::Fare.new(name: 'X', price_in_cents: 1000, currency: 'EUR', meta: {})
    seg = Models::Segment.new(
      departure_station: 'A',
      departure_at: '2025-01-01T08:00:00Z',
      arrival_station: 'B',
      arrival_at: DateTime.new(2025, 1, 1, 10, 0, 0),
      service_agencies: 'svc',
      duration_in_minutes: '120',
      changeovers: '0',
      products: 'train',
      fares: [fare]
    )

    expect(seg.departure_station).to eq('A')
    expect(seg.departure_at).to be_a(DateTime)
    expect(seg.arrival_at).to be_a(DateTime)
    expect(seg.duration_in_minutes).to eq(120)
    expect(seg.changeovers).to eq(0)
    expect(seg.products).to eq(['train'])
    expect(seg.fares).to eq([fare])
    expect(seg.to_h[:fares]).to eq([fare.to_h])
  end
end