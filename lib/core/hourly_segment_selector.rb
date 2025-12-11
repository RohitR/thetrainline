# frozen_string_literal: true

require 'set'

module Core
  class HourlySegmentSelector
    LOOKUP_HOUR_CAP = 24 * 7

    def initialize(segments:, departure_at:, limit:)
      @segments = segments
      @departure_at = departure_at
      @limit = limit
    end

    def call
      grouped = group_by_hour(@segments)
      pick_segments(grouped)
    end

    private

    def group_by_hour(segments)
      grouped = Hash.new { |h, k| h[k] = [] }
      segments.each do |s|
        key = hour_key(s.departure_at)
        grouped[key] << s
      end
      grouped.each_value(&:sort_by!)
      grouped
    end

    def pick_segments(grouped)
      results = []
      looked = Set.new
      cursor = @departure_at

      while needs_more?(results, looked)
        try_pick_hour(grouped, results, looked, cursor)
        cursor += Rational(1, 24)
      end

      fill_with_leftovers(results)
      results.first(@limit)
    end

    def needs_more?(results, looked)
      results.size < @limit && looked.size < LOOKUP_HOUR_CAP
    end

    def try_pick_hour(grouped, results, looked, cursor)
      key = hour_key(cursor)
      return if looked.include?(key)

      first_segment = grouped[key]&.first
      results << first_segment if first_segment
      looked << key
    end

    def fill_with_leftovers(results)
      return if results.size >= @limit

      leftovers = @segments.reject { |s| results.include?(s) }.sort_by(&:departure_at)
      leftovers.each { |s| results << s }
    end

    def hour_key(time)
      time.strftime('%Y-%m-%dT%H')
    end
  end
end
