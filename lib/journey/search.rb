# frozen_string_literal: true
require 'date'
require_relative 'response'
require_relative 'fare_calculator'
require_relative 'hourly_segment_selector'
require_relative 'segment'

module Journey
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
      response = Response.new(
        client.search_journeys(from: from, to: to, departure_at: departure_at)
      )

      calculator = FareCalculator.new(
        sections: response.sections,
        alternatives: response.alternatives
      )

      segments = response.journeys.values.map do |j|
        build_segment(j, calculator)
      end.compact

      HourlySegmentSelector.new(
        segments: segments,
        departure_at: departure_at,
        limit: limit
      ).call
    end

    private

    def build_segment(journey, calculator)
      legs = journey['legs'] || []
      return nil if legs.empty?

      Segment.new(
        departure_station: from,
        departure_at: DateTime.parse(journey['departAt']),
        arrival_station: to,
        arrival_at: DateTime.parse(journey['arriveAt']),
        service_agencies: ['thetrainline'],
        duration_in_minutes: parse_duration(journey['duration']),
        changeovers: legs.size - 1,
        products: journey['products'] || ['train'],
        fares: calculator.fares_for(journey)
      )
    end

    def parse_duration(str)
      return nil unless str
      hours = str[/(\d+)H/, 1].to_i
      minutes = str[/(\d+)M/, 1].to_i
      hours * 60 + minutes
    end
  end
end
