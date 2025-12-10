# frozen_string_literal: true
require "date"
require_relative "segment"
require_relative "fare"
require "set"

class JourneySearch
  DEFAULT_SEGMENTS = 10
  LOOKUP_HOUR_CAP = 24 * 7

  attr_reader :from, :to, :departure_at, :client, :segments_needed

  def initialize(from:, to:, departure_at:, client:, segments_needed: DEFAULT_SEGMENTS)
    @from = from
    @to = to
    @departure_at = departure_at.to_datetime
    @client = client
    @segments_needed = segments_needed
  end

  def call
    raw = client.search_journeys(from: from, to: to, departure_at: departure_at)
    journeys = raw.dig("journeySearch", "journeys") || []

    all_segments = journeys.map { |j| build_segment(j) }.compact

    select_next_hourly_segments(all_segments, segments_needed)
  end

  private

  def build_segment(journey)
    legs = journey["legs"]
    return nil if legs.nil? || legs.empty?

    first = legs.first
    last = legs.last

    fares = Array(journey["fares"]).map do |f|
      amount = f.dig("price", "amount") || f.dig("fare", "amount") || 0
      Fare.new(
        name: f["name"] || f["fareClass"] || "Unknown",
        price_in_cents: (amount.to_f * 100).to_i,
        currency: f.dig("price", "currency") || "GBP",
        meta: f
      )
    end

    Segment.new(
      departure_station: first.dig("origin", "name"),
      departure_at: DateTime.parse(first["departureDateTime"]),
      arrival_station: last.dig("destination", "name"),
      arrival_at: DateTime.parse(last["arrivalDateTime"]),
      service_agencies: ["thetrainline"],
      duration_in_minutes: journey["durationMinutes"],
      changeovers: legs.size - 1,
      products: journey["products"] || ["train"],
      fares: fares
    )
  rescue => e
    warn "Failed to build segment: #{e.message}"
    nil
  end

  def select_next_hourly_segments(segments, count)
    by_hour = Hash.new { |h, k| h[k] = [] }
    segments.each do |s|
      key = s.departure_at.strftime("%Y-%m-%dT%H")
      by_hour[key] << s
    end
    by_hour.each_value { |arr| arr.sort_by!(&:departure_at) }

    results = []
    current = departure_at
    looked = Set.new

    while results.size < count && looked.size < LOOKUP_HOUR_CAP
      key = current.strftime("%Y-%m-%dT%H")
      unless looked.include?(key)
        if (list = by_hour[key]) && !list.empty?
          results << list.first
        end
        looked << key
      end
      current += Rational(1, 24) # advance 1 hour
    end

    if results.size < count
      remaining = segments.reject { |s| results.include?(s) }.sort_by(&:departure_at)
      remaining.each { |s| results << s; break if results.size >= count }
    end

    results.first(count)
  end
end
