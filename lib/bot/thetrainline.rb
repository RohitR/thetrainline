# frozen_string_literal: true

require_relative '../clients/file_client'
require_relative '../journey/search'
module Bot
  module Thetrainline
    module_function

    def find(from, to, departure_at, options = {})
      client = options[:client] || Clients::FileClient.new
      service = Journey::Search.new(from: from, to: to, departure_at: departure_at, client: client)
      service.call
    end
  end
end
