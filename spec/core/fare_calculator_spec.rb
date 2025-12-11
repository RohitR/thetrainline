# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'spec_helper'
require 'core/fare_calculator'

RSpec.describe Core::FareCalculator do
  it 'returns [] when journey has no sections' do
    calc = Core::FareCalculator.new(sections: {}, alternatives: {})
    expect(calc.fares_for({})).to eq([])
  end

  it 'builds combinations and calculates total price and currency' do
    sections = {
      's1' => { 'alternatives' => %w[a1 a2] },
      's2' => { 'alternatives' => ['b1'] }
    }
    alternatives = {
      'a1' => { 'id' => 'a1', 'price' => { 'amount' => '10.50', 'currencyCode' => 'GBP' } },
      'a2' => { 'id' => 'a2', 'price' => { 'amount' => '5.00', 'currencyCode' => 'GBP' } },
      'b1' => { 'id' => 'b1', 'price' => { 'amount' => '2.25', 'currencyCode' => 'GBP' } }
    }

    calc = Core::FareCalculator.new(sections: sections, alternatives: alternatives)
    fares = calc.fares_for('sections' => %w[s1 s2])
    expect(fares.map(&:price_in_cents)).to contain_exactly((10.5 + 2.25) * 100.to_i, (5.0 + 2.25) * 100.to_i)
    expect(fares.all? { |f| f.currency == 'GBP' }).to be true
    expect(fares.map(&:name)).to include('a1+b1', 'a2+b1')
  end

  it 'defaults currency to EUR if missing' do
    sections = { 's' => { 'alternatives' => ['x'] } }
    alternatives = { 'x' => { 'id' => 'x', 'price' => { 'amount' => '1.0' } } }
    calc = Core::FareCalculator.new(sections: sections, alternatives: alternatives)
    fare = calc.fares_for('sections' => ['s']).first
    expect(fare.currency).to eq('EUR')
    expect(fare.price_in_cents).to eq(100)
  end
end
# rubocop:enable Metrics/BlockLength
