# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'spec_helper'
require 'date'
require_relative '../../lib/core/search'

RSpec.describe Core::Search do
  let(:from) { 'london' }
  let(:to) { 'paris' }
  let(:departure_at) { DateTime.new(2025, 12, 10, 6, 0, 0) }
  let(:client) { double('client') }

  let(:response) do
    {
      'data' => {
        'journeySearch' => {
          'journeys' => {
            'journey-1' => {
              'legs' => %w[
                leg-6839bc17-45fe-4782-8fc0-df1bc15624b4
                leg-cd4f84d7-29d1-4424-9f16-a6028379f703
              ],
              'id' => 'journey-1',
              'sections' => ['sec-1'],
              'departAt' => '2025-12-10T06:05:00Z',
              'arriveAt' => '2025-12-10T09:05:00Z',
              'duration' => 'PT3H0M'
            }
          },
          'sections' => {
            'sec-1' => { 'alternatives' => ['alt-1'] }
          },
          'alternatives' => {
            'alt-1' => {
              'id' => 'alt-1',
              'price' => { 'amount' => 10.0, 'currencyCode' => 'GBP' },
              'name' => 'Advance Single'
            }
          }
        }
      }
    }
  end

  before do
    allow(client).to receive(:search_journeys).and_return(response)
  end

  it 'returns Segment objects with parsed duration and fares' do
    service = described_class.new(from: from, to: to, departure_at: departure_at, client: client, segments_needed: 1)
    segments = service.call

    expect(segments).to be_an(Array)
    expect(segments.size).to eq(1)

    seg = segments.first
    expect(seg).to be_a(Models::Segment)

    expect(seg.departure_at).to be_a(DateTime).or be_a(Time)
    expect(seg.arrival_at).to be_a(DateTime).or be_a(Time)

    expect(seg.departure_station).to eq('london')
    expect(seg.arrival_station).to eq('paris')

    expect(seg.duration_in_minutes).to eq(180)

    expect(seg.fares).to be_an(Array)
    fare = seg.fares.first
    expect(fare).to respond_to(:price_in_cents)
    expect(fare.price_in_cents).to eq(1000)
    expect(fare.currency).to eq('GBP')
  end
end
# rubocop:enable Metrics/BlockLength
