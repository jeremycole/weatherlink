# frozen_string_literal: true

module WeatherLink
  class Station < HashWrapper
    LocalSensor = Struct.new(:device, :host, keyword_init: true) do
      def client
        @client ||= LocalClient.new(host: host)
      end

      def current_conditions
        client.current_conditions
      end
    end

    attr_reader :client

    def initialize(client, data)
      @client = client
      super(data)
    end

    def to_s
      "#<#{self.class.name} station_id=#{station_id} gateway_id_hex=#{gateway_id_hex} (#{station_name})>"
    end

    def inspect
      to_s
    end

    def sensors
      @sensors ||= client.sensors.select { |sensor| sensor.station_id == station_id }
    end

    def sensor(lsid)
      sensors.select { |sensor| sensor.lsid == lsid }.first
    end

    def current
      sensors = client.api.current(station_id)['sensors'].map do |sensor|
        SensorData.new(client, sensor)
      end

      SensorDataCollection.new(client, sensors)
    end

    def last_seconds(seconds)
      sensors = client.api.last_seconds(station_id, seconds)['sensors'].map do |sensor|
        SensorData.new(client, sensor)
      end

      SensorDataCollection.new(client, sensors)
    end

    def last_hour
      last_seconds(3600)
    end

    def last_day
      last_seconds(86_400)
    end

    def local_sensors
      @local_sensors ||= current.health.select { |s| s.include?('ip_v4_address') }.map do |health|
        sensor = client.sensor_by_lsid(health.lsid)
        device_id_hex = sensor.parent_device_id_hex
        device = client.node_by_device_id_hex(device_id_hex) || client.stations_by_device_id_hex(device_id_hex)
        LocalSensor.new(device: device, host: health.fetch('ip_v4_address'))
      end
    end
  end
end
