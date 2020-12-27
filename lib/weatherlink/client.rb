# frozen_string_literal: true

module WeatherLink
  class Client
    attr_reader :api

    def initialize(api_key:, api_secret:, station_units: IMPERIAL_WEATHER_UNITS, desired_units: METRIC_WEATHER_UNITS)
      @api = APIv2.new(api_key: api_key, api_secret: api_secret, units: station_units)
      @desired_units = desired_units
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

    def stations
      @stations ||= api.station['stations'].map do |data|
        Station.new(self, data) if data
      end
    end

    def station
      stations.first
    end

    def stations_by_device_id_hex(device_id_hex)
      stations.select { |s| s.gateway_id_hex == device_id_hex }.first
    end

    def nodes
      @nodes ||= api.nodes['nodes'].map do |data|
        Node.new(self, data)
      end
    end

    def node_by_device_id_hex(device_id_hex)
      nodes.select { |n| n.device_id_hex == device_id_hex }.first
    end

    def sensors
      @sensors ||= api.sensors['sensors'].map do |data|
        Sensor.new(self, data)
      end
    end

    def sensor_by_lsid(lsid)
      sensors.select { |s| s.lsid == lsid }.first
    end
  end
end
