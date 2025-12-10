# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Segment do
  let(:fare) { Fare.new(name: 'Advance', price_in_cents: 1999, currency: 'GBP') }

  it 'is immutable and converts times to DateTime' do
    seg = Segment.new(
      departure_station: 'A',
      departure_at: Time.new(2025, 12, 10, 8, 0, 0),
      arrival_station: 'B',
      arrival_at: '2025-12-10T09:05:00+00:00',
      service_agencies: ['thetrainline'],
      duration_in_minutes: 65,
      changeovers: 0,
      products: ['train'],
      fares: [fare]
    )

    expect(seg.departure_at).to be_a(DateTime)
    expect(seg.fares.first).to be_a(Fare)
    expect(seg.to_h[:departure_station]).to eq('A')
  end
end
