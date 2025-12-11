# frozen_string_literal: true

require 'bundler/setup'
require 'rspec'
require 'date'
require_relative '../lib/core/fare_calculator'
require_relative '../lib/core/hourly_segment_selector'
require_relative '../lib/core/response'
require_relative '../lib/clients/file_client'
require_relative '../lib/bot/thetrainline'
require_relative '../lib/core/search'
