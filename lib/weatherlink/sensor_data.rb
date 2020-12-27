# frozen_string_literal: true

module WeatherLink
  class SensorData < SimpleDelegator
    attr_reader :client, :records, :sensor_data

    def initialize(client, sensor_data)
      @client = client
      @sensor_data = HashWrapper.new(sensor_data)
      @records = @sensor_data['data'].map do |data|
        SensorRecord.new(client, client.attach_units(data))
      end
      super(@records.first)
    end

    def to_s
      "#<#{self.class.name} lsid=#{lsid} (#{record_type.description}, #{records.size} records)>"
    end

    def inspect
      to_s
    end

    def lsid
      sensor_data.lsid
    end

    def sensor
      @sensor ||= @client.sensors.select { |sensor| sensor.lsid == lsid }.first
    end

    def sensor_type
      sensor_data.sensor_type
    end

    def record_type
      @record_type ||= client.api.class.record_type(sensor_data.data_structure_type)
    end

    def health?
      record_type.health?
    end

    def current_conditions?
      record_type.current_conditions?
    end

    def archive?
      record_type.archive?
    end

    def weather?
      record_type.current_conditions? || record_type.archive?
    end

    def description
      record_type.description
    end
  end
end
