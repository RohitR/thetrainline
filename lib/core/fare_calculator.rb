# frozen_string_literal: true

require_relative '../models/fare'

module Core
  class FareCalculator
    def initialize(sections:, alternatives:)
      @sections = sections
      @alternatives = alternatives
    end

    def fares_for(journey)
      section_ids = journey['sections'] || []
      return [] if section_ids.empty?

      alt_groups = section_ids.map { |sid| alt_list_for_section(sid) }
      combos = alt_groups.first.product(*alt_groups.drop(1))

      combos.map { |combo| build_fare(combo) }.sort_by(&:price_in_cents)
    end

    private

    def alt_list_for_section(id)
      section = @sections[id] || {}
      alt_ids = section['alternatives'] || []
      alt_ids.map { |aid| @alternatives[aid] }.compact
    end

    def build_fare(combo)
      items = combo.is_a?(Array) ? combo : [combo]

      total = items.sum { |alt| alt.dig('price', 'amount').to_f }
      currency = items.first.dig('price', 'currencyCode') || 'EUR'

      Models::Fare.new(
        name: items.map { |c| c['id'] }.join('+'),
        price_in_cents: (total * 100).to_i,
        currency: currency,
        meta: items
      )
    end
  end
end
