#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
require 'json'
require 'securerandom'
require 'time'
require 'fileutils'

class MockJourneyGenerator
  def initialize(from:, to:, count:)
    @from = from
    @to = to
    @count = count.to_i
  end

  def run
    journeys = {}
    sections = {}
    alternatives = {}

    @count.times do
      journey_id = uuid('journey')
      depart_at, arrive_at = random_times

      section_ids = [uuid('section'), uuid('section')]
      leg_ids = [uuid('leg'), uuid('leg')]

      # Each journey links to its two sections
      section_ids.each do |sid|
        sections[sid] = generate_section(alternatives)
      end

      journeys[journey_id] = {
        'sections' => section_ids,
        'id' => journey_id,
        'direction' => 'outward',
        'legs' => leg_ids,
        'departAt' => depart_at,
        'arriveAt' => arrive_at,
        'duration' => iso_duration(depart_at, arrive_at),
        'hash' => random_hash,
        'hasFirstClassRecommendedStationPair' => false,
        'distanceInKm' => 0
      }
    end

    output = {
      'data' => {
        'journeySearch' => {
          'journeys' => journeys,
          'id' => uuid,
          'expiresAt' => (Time.now.utc + 3600).iso8601,
          'alternatives' => alternatives,
          'sections' => sections
        }
      }
    }

    write_file(output)
    output
  end

  private

  def generate_section(alternatives)
    alt_ids = 1.upto(rand(2..4)).map do
      alt_id = "#{uuid}%alternative-#{SecureRandom.uuid}"
      alternatives[alt_id] = {
        'id' => alt_id,
        'price' =>
        { 'amount' => random_price, 'currencyCode' => 'EUR', 'currencyConversionApplied' => false }
      }
      alt_id
    end
    { 'alternatives' => alt_ids, 'mixedLegComforts' => false, 'id' => uuid('section') }
  end

  def random_times
    base = Time.now + rand(1..3) * 3600
    depart = base
    arrive = base + rand(4..10) * 3600
    [depart.iso8601, arrive.iso8601]
  end

  def iso_duration(start_iso, end_iso)
    start_t = Time.parse(start_iso)
    end_t = Time.parse(end_iso)
    seconds = end_t - start_t

    hours = (seconds / 3600).floor
    minutes = ((seconds % 3600) / 60).floor

    "PT#{hours}H#{minutes}M"
  end

  def random_price
    (rand(50..350) + rand.round(2)).round(2)
  end

  def random_hash
    SecureRandom.base64(8)
  end

  def uuid(prefix = nil)
    prefix ? "#{prefix}-#{SecureRandom.uuid}" : SecureRandom.uuid
  end

  def write_file(data)
    FileUtils.mkdir_p('data')
    file_name = "data/#{@from.downcase}_#{@to.downcase}.json"
    File.write(file_name, JSON.pretty_generate(data))
    puts "Generated #{file_name}"
  end
end

# CLI execution
if __FILE__ == $PROGRAM_NAME
  from, to, count = ARGV
  unless from && to && count
    puts 'Usage: ruby generate_mock.rb FROM TO COUNT'
    exit 1
  end

  MockJourneyGenerator.new(from: from, to: to, count: count).run
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
