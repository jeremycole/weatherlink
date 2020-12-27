# frozen_string_literal: true

module WeatherLink
  class Node < HashWrapper
    attr_reader :client

    def initialize(client, data)
      @client = client
      super(data)
    end

    def to_s
      "#<#{self.class.name} device_id_hex=#{device_id_hex} (#{description})>"
    end

    def inspect
      to_s
    end

    def description
      "#{station_name} - #{node_name}"
    end
  end
end
