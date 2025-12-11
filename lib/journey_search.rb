# frozen_string_literal: true

require 'date'
require_relative 'segment'
require_relative 'fare'
require 'set'

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

    search = raw.dig('data', 'journeySearch') || {}
    journeys_hash = search['journeys'] || {}
    sections_hash = search['sections'] || {}
    alternatives_hash = search['alternatives'] || {}

    segments = journeys_hash.values.map do |j|
      build_segment(
        journey: j,
        sections_hash: sections_hash,
        alternatives_hash: alternatives_hash
      )
    end.compact

    select_next_hourly_segments(segments, segments_needed)
  end

  private

  def build_segment(journey:, sections_hash:, alternatives_hash:)
    legs = journey['legs']
    return nil if legs.nil? || legs.empty?

    first = legs.first
    last = legs.last

    fares = extract_fares(journey, sections_hash, alternatives_hash)

    Segment.new(
      departure_station: from,
      departure_at: DateTime.parse(journey['departAt']),
      arrival_station: to,
      arrival_at: DateTime.parse(journey['arriveAt']),
      service_agencies: ['thetrainline'],
      duration_in_minutes: parse_duration(journey['duration']),
      changeovers: legs.size - 1,
      products: journey['products'] || ['train'],
      fares: fares
    )
  rescue StandardError => e
    warn "Failed to build segment: #{e.message}"
    nil
  end

  def parse_duration(str)
    return nil unless str
    hours = str[/(\d+)H/, 1].to_i
    minutes = str[/(\d+)M/, 1].to_i
    (hours * 60) + minutes
  end


  def extract_fares(journey, sections_by_id, alternatives_by_id)
    section_ids = journey['sections'] || []
    return [] if section_ids.empty?

    section_alternatives = section_ids.map do |sid|
      section = sections_by_id[sid]
      alt_ids = section['alternatives'] || []
      alt_ids.map { |aid| alternatives_by_id[aid] }.compact
    end

    combinations = section_alternatives.first.product(*section_alternatives.drop(1))

    fares = combinations.map do |combo|
      combo = [combo] unless combo.is_a?(Array)

      total_price = combo.sum { |alt| alt.dig('price', 'amount').to_f }
      currency = combo.first.dig('price', 'currencyCode') || "EUR"

      Fare.new(
        name: combo.map { |c| c['id'] }.join('+'),
        price_in_cents: (total_price * 100).to_i,
        currency: currency,
        meta: combo
      )
    end

    fares.sort_by!(&:price_in_cents)
  end

  def select_next_hourly_segments(segments, count)
    by_hour = Hash.new { |h, k| h[k] = [] }
    segments.each do |s|
      key = s.departure_at.strftime('%Y-%m-%dT%H')
      by_hour[key] << s
    end

    by_hour.each_value { |arr| arr.sort_by!(&:departure_at) }

    results = []
    current = departure_at
    looked = Set.new

    while results.size < count && looked.size < LOOKUP_HOUR_CAP
      key = current.strftime('%Y-%m-%dT%H')
      unless looked.include?(key)
        if (list = by_hour[key]) && !list.empty?
          results << list.first
        end
        looked << key
      end
      current += Rational(1, 24)
    end

    if results.size < count
      remaining = segments.reject { |s| results.include?(s) }.sort_by(&:departure_at)
      remaining.each do |s|
        results << s
        break if results.size >= count
      end
    end

    results.first(count)
  end
end
