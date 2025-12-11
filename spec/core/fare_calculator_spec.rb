# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'spec_helper'
require_relative '../../lib/core/fare_calculator'

RSpec.describe Core::FareCalculator do
  describe '#fares_for' do
    let(:calculator) { described_class.new(sections: sections, alternatives: alternatives) }

    context 'multiple sections with alternatives' do
      let(:sections) do
        {
          'sec-1' => { 'alternatives' => %w[a1 a2] },
          'sec-2' => { 'alternatives' => %w[b1 b2] }
        }
      end

      let(:alternatives) do
        {
          'a1' => { 'id' => 'a1', 'price' => { 'amount' => 1.0, 'currencyCode' => 'EUR' } },
          'a2' => { 'id' => 'a2', 'price' => { 'amount' => 2.0, 'currencyCode' => 'EUR' } },
          'b1' => { 'id' => 'b1', 'price' => { 'amount' => 3.0, 'currencyCode' => 'EUR' } },
          'b2' => { 'id' => 'b2', 'price' => { 'amount' => 4.0, 'currencyCode' => 'EUR' } }
        }
      end

      let(:journey) { { 'sections' => %w[sec-1 sec-2] } }

      it 'returns all combinations and sorts by price_in_cents ascending' do
        fares = calculator.fares_for(journey)
        expect(fares.map(&:price_in_cents)).to eq([400, 500, 500, 600])
        expect(fares.map(&:name)).to include('a1+b1', 'a1+b2', 'a2+b1', 'a2+b2')
        expect(fares.all? { |f| f.currency == 'EUR' }).to be true
      end
    end

    context 'section with zero alternatives' do
      let(:sections) do
        {
          'sec-1' => { 'alternatives' => ['a1'] },
          'sec-2' => { 'alternatives' => [] } # no alternatives here
        }
      end

      let(:alternatives) do
        {
          'a1' => { 'id' => 'a1', 'price' => { 'amount' => 5.0, 'currencyCode' => 'EUR' } }
        }
      end

      let(:journey) { { 'sections' => %w[sec-1 sec-2] } }

      it 'returns an empty array when any section has no alternatives' do
        expect(calculator.fares_for(journey)).to eq([])
      end
    end

    context 'rounding behavior for prices like 1.995' do
      let(:sections) do
        { 'sec-1' => { 'alternatives' => ['a1'] } }
      end

      let(:alternatives) do
        { 'a1' => { 'id' => 'a1', 'price' => { 'amount' => 1.995, 'currencyCode' => 'EUR' } } }
      end

      let(:journey) { { 'sections' => ['sec-1'] } }

      it 'rounds to nearest cent (1.995 -> 200 cents)' do
        fares = calculator.fares_for(journey)
        expect(fares.size).to eq(1)
        expect(fares.first.price_in_cents).to eq(200)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
