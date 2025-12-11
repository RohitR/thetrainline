# frozen_string_literal: true

require "json"
require_relative "base_client"

module Clients
  class FileClient < BaseClient
    BASE_PATH = "data"

    def search_journeys(from:, to:, departure_at:)
      cache_key = "#{from}-#{to}-#{departure_at}"

      cache_fetch(cache_key) do
        file_path = "#{BASE_PATH}/#{from}_#{to}.json"
        raise "No mock file found: #{file_path}" unless File.exist?(file_path)

        JSON.parse(File.read(file_path))
      end
    end
  end
end
