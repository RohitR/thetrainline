# frozen_string_literal: true

require "json"

module Clients
  class FileClient
    def initialize(file_path: nil)
      @file_path = file_path || File.expand_path("../../../data/journeys_sample.json", __FILE__)
    end

    def search_journeys(from:, to:, departure_at:)
      raw = File.read(@file_path)
      JSON.parse(raw)
    end
  end
end
