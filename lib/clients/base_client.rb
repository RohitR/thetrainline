# frozen_string_literal: true

module Clients
  class BaseClient
    def initialize
      @cache = {}
    end

    private

    def cache_fetch(key)
      return @cache[key] if @cache.key?(key)
      @cache[key] = yield
    end
  end
end
