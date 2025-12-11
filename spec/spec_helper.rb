# frozen_string_literal: true

require 'bundler/setup'
require 'rspec'
require 'date'
require_relative '../lib/journey/fare_calculator'
require_relative '../lib/journey/fare'
require_relative '../lib/journey/hourly_segment_selector'
require_relative '../lib/journey/segment'
require_relative '../lib/journey/response'
require_relative '../lib/clients/file_client'
require_relative '../lib/bot/thetrainline'
require_relative '../lib/journey/search'
