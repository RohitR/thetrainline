# frozen_string_literal: true

require 'date'
require_relative 'response'
require_relative 'fare_calculator'
require_relative 'hourly_segment_selector'
require_relative '../models/segment'

module Core
  class Search
    DEFAULT_SEGMENTS = 10

    attr_reader :from, :to, :departure_at, :client, :limit

    def initialize(from:, to:, departure_at:, client:, segments_needed: DEFAULT_SEGMENTS)
      @from = from
      @to = to
      @departure_at = departure_at.to_datetime
      @client = client
      @limit = segments_needed
    end

    def call
      journeys = fetch_journeys
      calculator = build_fare_calculator(journeys)
      segments = build_segments(journeys, calculator)

      select_segments(segments)
    end

    private

    def fetch_journeys
      raw = client.search_journeys(from: from, to: to, departure_at: departure_at)
      Response.new(raw)
    end

    def build_fare_calculator(response)
      FareCalculator.new(
        sections: response.sections,
        alternatives: response.alternatives
      )
    end

    def build_segments(response, calculator)
      response.journeys.values.map do |journey|
        build_segment(journey, calculator)
      end.compact
    end

    def select_segments(segments)
      HourlySegmentSelector.new(
        segments: segments,
        departure_at: departure_at,
        limit: limit
      ).call
    end

    def build_segment(journey, calculator)
      return nil if (journey['legs'] || []).empty?

      Models::Segment.new(
        departure_station: from,
        departure_at: parse_dt(journey['departAt']), arrival_station: to,
        arrival_at: parse_dt(journey['arriveAt']),
        service_agencies: ['thetrainline'],
        duration_in_minutes: parse_duration(journey['duration']),
        changeovers: changeovers(journey),
        products: journey['products'] || ['train'], fares: calculator.fares_for(journey)
      )
    end

    def parse_dt(str)
      DateTime.parse(str)
    end

    def changeovers(journey)
      legs = journey['legs'] || []
      legs.size - 1
    end

    def parse_duration(str)
      return nil unless str

      hours = str[/(\d+)H/, 1].to_i
      minutes = str[/(\d+)M/, 1].to_i
      hours * 60 + minutes
    end
  end
end
