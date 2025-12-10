# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bot::Thetrainline integration' do
  it 'returns 10 segments from facade' do
    data_file = File.expand_path('fixtures/journeys_sample.json', __dir__)
    departure_at = DateTime.new(2025, 12, 10, 6, 0, 0)
    segments = Bot::Thetrainline.find('Manchester Piccadilly', 'London Euston', departure_at, data_file: data_file)
    expect(segments.size).to eq(10)
    expect(segments.first).to be_a(Segment)
  end
end
