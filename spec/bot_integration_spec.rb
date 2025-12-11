# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bot::Thetrainline integration' do
  it 'returns 10 segments from facade' do
    departure_at = DateTime.new(2025, 12, 10, 6, 0, 0)
    segments = Bot::Thetrainline.find('berlin', 'paris', departure_at)
    expect(segments.size).to eq(10)
    expect(segments.first).to be_a(Models::Segment)
  end
end
