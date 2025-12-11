# frozen_string_literal: true
require 'spec_helper'
require 'journey/fare'

RSpec.describe Journey::Fare do
  it 'exposes attributes and to_h' do
    fare = Journey::Fare.new(name: 'A', price_in_cents: '1234', currency: 'EUR', meta: { foo: 'bar' })
    expect(fare.name).to eq('A')
    expect(fare.price_in_cents).to eq(1234)
    expect(fare.currency).to eq('EUR')
    expect(fare.meta).to eq({ foo: 'bar' })
    expect(fare.to_h).to eq({
      name: 'A',
      price_in_cents: 1234,
      currency: 'EUR',
      meta: { foo: 'bar' }
    })
  end
end