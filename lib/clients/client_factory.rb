# frozen_string_literal: true

require_relative "file_client"
require_relative "http_client"

module Clients
  class ClientFactory
    def self.build
      if ENV["USE_REAL_CLIENT"] == "true"
        HttpClient.new
      else
        FileClient.new
      end
    end
  end
end
