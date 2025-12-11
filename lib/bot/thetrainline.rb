# frozen_string_literal: true

require_relative '../clients/client_factory'
require_relative '../core/search'
module Bot
  module Thetrainline
    module_function

    def find(from, to, departure_at)
      client = Clients::ClientFactory.build
      service = Core::Search.new(from: from, to: to, departure_at: departure_at, client: client)
      service.call
    end
  end
end
