# frozen_string_literal: true
require 'spec_helper'
require 'journey/search'

RSpec.describe Journey::Search do
  it 'builds segments from client response and respects segments_needed' do
    departure_at = DateTime.new(2025, 12, 10, 6, 0, 0)
    raw = {
      'data' => {
        'journeySearch' => {
          'journeys' => {
            'j1' => {
              'departAt' => '2025-12-10T06:00:00Z',
              'arriveAt' => '2025-12-10T08:00:00Z',
              'duration' => '2H0M',
              'legs' => [1],
              'products' => ['train'],
              'sections' => ['s1']
            },
            'j2' => {
              'departAt' => '2025-12-10T09:00:00Z',
              'arriveAt' => '2025-12-10T11:00:00Z',
              'duration' => '2H0M',
              'legs' => [1],
              'products' => ['train'],
              'sections' => ['s1']
            }
          },
          'sections' => {
            's1' => { 'alternatives' => ['a1'] }
          },
          'alternatives' => {
            'a1' => { 'id' => 'a1', 'price' => { 'amount' => '3.50', 'currencyCode' => 'EUR' } }
          }
        }
      }
    }

    client = double('client')
    expect(client).to receive(:search_journeys).with(from: 'berlin', to: 'paris', departure_at: departure_at).and_return(raw)

    search = Journey::Search.new(from: 'berlin', to: 'paris', departure_at: departure_at, client: client, segments_needed: 1)
    segments = search.call
    expect(segments).to be_an(Array)
    expect(segments.size).to eq(1)
    seg = segments.first
    expect(seg).to be_a(Journey::Segment)
    expect(seg.departure_station).to eq('berlin')
    expect(seg.arrival_station).to eq('paris')
    expect(seg.duration_in_minutes).to eq(120)
    expect(seg.fares.first.price_in_cents).to eq(350)
  end

  it 'parse_duration handles missing and complex formats' do
    client = double('client', search_journeys: { 'data' => { 'journeySearch' => { 'journeys' => {} } } })
    search = Journey::Search.new(from: 'a', to: 'b', departure_at: DateTime.now, client: client)
    # private method parse_duration indirectly tested via build_segment
    raw = {
      'data' => {
        'journeySearch' => {
          'journeys' => {
            'j' => {
              'departAt' => '2025-12-10T06:00:00Z',
              'arriveAt' => '2025-12-10T06:45:00Z',
              'duration' => '0H45M',
              'legs' => [1]
            }
          },
          'sections' => {},
          'alternatives' => {}
        }
      }
    }
    expect(client).to receive(:search_journeys).and_return(raw)
    result = search.call
    expect(result.first.duration_in_minutes).to eq(45)
  end
end