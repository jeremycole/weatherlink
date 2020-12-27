# frozen_string_literal: true

require 'ruby-units'

module WeatherLink
  class LocalClient
    attr_reader :api, :desired_units

    def initialize(host:, station_units: IMPERIAL_WEATHER_UNITS, desired_units: METRIC_WEATHER_UNITS)
      @api = LocalAPIv1.new(host: host, units: station_units)
      @desired_units = desired_units
    end

    META_KEYS = %w[lsid data_structure_type txid].freeze

    def transform_like_api_v2(hash)
      hash.select { |k, _| META_KEYS.include?(k) }.merge('data' => [{
        'ts' => Time.now.to_i,
      }.merge(hash.reject { |k, _| META_KEYS.include?(k) })])
    end

    def attach_units(data)
      data.map do |field, value|
        unit = api.unit_for(field)
        [field, unit ? Unit.new("#{value} #{unit}") : value]
      end.to_h
    end

    def desired_unit_for(field)
      desired_units.fetch(api.type_for(field))
    end

    def convert(field, value)
      desired_unit = desired_unit_for(field)
      return value unless desired_unit

      value.convert_to(desired_unit)
    end

    def current_conditions
      sensors = api.current_conditions['conditions'].map do |conditions|
        SensorData.new(self, transform_like_api_v2(conditions))
      end

      SensorDataCollection.new(self, sensors)
    end

    def stations
      @stations ||= api.station['stations'].map do |data|
        Station.new(self, data) if data
      end
    end

    def sensors
      @sensors ||= api.sensors['sensors'].map do |data|
        Sensor.new(self, data)
      end
    end
  end
end
