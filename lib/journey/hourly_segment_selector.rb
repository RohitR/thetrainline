# frozen_string_literal: true

require 'set'

module Journey
  class HourlySegmentSelector
    LOOKUP_HOUR_CAP = 24 * 7

    def initialize(segments:, departure_at:, limit:)
      @segments = segments
      @departure_at = departure_at
      @limit = limit
    end

    def call
      grouped = group_by_hour(@segments)
      choose_segments(grouped)
    end

    private

    def group_by_hour(segments)
      grouped = Hash.new { |h, k| h[k] = [] }
      segments.each do |s|
        key = s.departure_at.strftime('%Y-%m-%dT%H')
        grouped[key] << s
      end
      grouped.each_value(&:sort_by!)
      grouped
    end

    def choose_segments(grouped)
      results = []
      looked = Set.new
      cursor = @departure_at

      while results.size < @limit && looked.size < LOOKUP_HOUR_CAP
        key = cursor.strftime('%Y-%m-%dT%H')

        if !looked.include?(key)
          results << grouped[key]&.first if grouped[key]&.any?
          looked << key
        end

        cursor += Rational(1, 24)
      end

      if results.size < @limit
        leftover = @segments.reject { |s| results.include?(s) }.sort_by(&:departure_at)
        leftover.each { |s| results << s }
      end

      results.first(@limit)
    end
  end
end
