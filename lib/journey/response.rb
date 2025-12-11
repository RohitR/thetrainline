# frozen_string_literal: true

module Journey
  class Response
    attr_reader :raw

    def initialize(raw)
      @raw = raw
    end

    def journeys
      raw.dig('data', 'journeySearch', 'journeys') || {}
    end

    def sections
      raw.dig('data', 'journeySearch', 'sections') || {}
    end

    def alternatives
      raw.dig('data', 'journeySearch', 'alternatives') || {}
    end
  end
end