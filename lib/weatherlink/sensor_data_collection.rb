# frozen_string_literal: true

module WeatherLink
  class SensorDataCollection < SimpleDelegator
    attr_reader :client

    def initialize(client, sensors)
      @client = client
      super(sensors)
    end

    def to_s
      "#<#{self.class.name} (#{size} sensors)>"
    end

    def inspect
      to_s
    end

    def current_conditions
      SensorDataCollection.new(client, select(&:current_conditions?))
    end

    def archive
      SensorDataCollection.new(client, select(&:archive?))
    end

    def weather
      SensorDataCollection.new(client, select(&:weather?))
    end

    def health
      SensorDataCollection.new(client, select(&:health?))
    end
  end
end
