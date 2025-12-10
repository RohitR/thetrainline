# frozen_string_literal: true

require 'date'

class Segment
  attr_reader :departure_station, :departure_at, :arrival_station, :arrival_at,
              :service_agencies, :duration_in_minutes, :changeovers, :products, :fares

  def initialize(departure_station:, departure_at:, arrival_station:, arrival_at:,
                 service_agencies:, duration_in_minutes:, changeovers:, products:, fares:)
    @departure_station = departure_station
    @departure_at = to_datetime(departure_at)
    @arrival_station = arrival_station
    @arrival_at = to_datetime(arrival_at)
    @service_agencies = Array(service_agencies)
    @duration_in_minutes = duration_in_minutes.to_i
    @changeovers = changeovers.to_i
    @products = Array(products)
    @fares = Array(fares).freeze
    freeze
  end

  def to_h
    {
      departure_station: departure_station,
      departure_at: departure_at,
      arrival_station: arrival_station,
      arrival_at: arrival_at,
      service_agencies: service_agencies,
      duration_in_minutes: duration_in_minutes,
      changeovers: changeovers,
      products: products,
      fares: fares.map(&:to_h)
    }
  end

  private

  def to_datetime(val)
    case val
    when String then DateTime.parse(val)
    when Time then val.to_datetime
    when DateTime then val
    else val
    end
  end
end
