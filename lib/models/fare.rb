# frozen_string_literal: true

module Models
  class Fare
    attr_reader :name, :price_in_cents, :currency, :meta

    def initialize(name:, price_in_cents:, currency:, meta: {})
      @name = name
      @price_in_cents = price_in_cents.to_i
      @currency = currency
      @meta = meta.freeze
      freeze
    end

    def to_h
      {
        name: name,
        price_in_cents: price_in_cents,
        currency: currency,
        meta: meta
      }
    end
  end
end