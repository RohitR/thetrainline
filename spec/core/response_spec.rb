# frozen_string_literal: true
require 'spec_helper'
require 'core/response'

RSpec.describe Core::Response do
  it 'returns nested values or defaults' do
    raw = { 'data' => { 'journeySearch' => { 'journeys' => { 'a' => 1 }, 'sections' => { 's' => 2 }, 'alternatives' => { 'alt' => 3 } } } }
    resp = Core::Response.new(raw)
    expect(resp.journeys).to eq({ 'a' => 1 })
    expect(resp.sections).to eq({ 's' => 2 })
    expect(resp.alternatives).to eq({ 'alt' => 3 })

    empty_resp = Core::Response.new({})
    expect(empty_resp.journeys).to eq({})
    expect(empty_resp.sections).to eq({})
    expect(empty_resp.alternatives).to eq({})
  end
end