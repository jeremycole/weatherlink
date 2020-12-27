# frozen_string_literal: true

module WeatherLink
  class Sensor < HashWrapper
    attr_reader :client

    def initialize(client, data)
      @client = client
      super(data)
    end

    def to_s
      "#<#{self.class.name} lsid=#{lsid} (#{description})>"
    end

    def inspect
      to_s
    end

    def description
      "#{manufacturer} - #{product_name}"
    end
  end
end
