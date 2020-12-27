# frozen_string_literal: true

require 'weatherlink/version'
require 'ruby-units'

module WeatherLink
  class Error < StandardError; end

  UNIT_TYPES = %i[
    temperature
    humidity
    wind_speed
    pressure
    wind_direction
    rain_quantity
    rain_rate
    solar_radiation
  ].freeze

  Units = Struct.new(*UNIT_TYPES, keyword_init: true) do
    def fetch(key)
      return send(key.to_sym) if key && respond_to?(key.to_sym)

      nil
    end
  end

  METRIC_WEATHER_UNITS = Units.new(
    temperature: 'tempC',
    humidity: '%',
    pressure: 'hPa',
    wind_speed: 'm/s',
    wind_direction: 'deg',
    rain_quantity: 'cm',
    rain_rate: 'cm/h',
    solar_radiation: 'W/m^2'
  )

  IMPERIAL_WEATHER_UNITS = Units.new(
    temperature: 'tempF',
    humidity: '%',
    pressure: 'inHg',
    wind_speed: 'mph',
    wind_direction: 'deg',
    rain_quantity: 'in',
    rain_rate: 'in/h',
    solar_radiation: 'W/m^2'
  )

  SystemType = Struct.new(:name, keyword_init: true)

  RecordType = Struct.new(:id, :system, :name, :type, keyword_init: true) do
    def description
      "#{system.name} - #{name}"
    end

    def current_conditions?
      type == :current_conditions
    end

    def archive?
      type == :archive
    end

    def health?
      type == :health
    end
  end
end

require 'weatherlink/hash_wrapper'

require 'weatherlink/api_v2'
require 'weatherlink/client'

require 'weatherlink/local_api_v1'
require 'weatherlink/local_client'

require 'weatherlink/data_record'
require 'weatherlink/sensor_data'
require 'weatherlink/sensor_record'
require 'weatherlink/sensor_data_collection'

require 'weatherlink/station'
require 'weatherlink/node'
require 'weatherlink/sensor'
