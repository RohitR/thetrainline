# frozen_string_literal: true

require_relative "base_client"

module Clients
  class HttpClient < BaseClient
    def search_journeys(from:, to:, departure_at:)
      raise NotImplementedError,
            "HTTP client not implemented. Use FileClient for now."
    end
  end
end
