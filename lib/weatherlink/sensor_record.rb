# frozen_string_literal: true

module WeatherLink
  class SensorRecord < HashWrapper
    attr_reader :client

    def initialize(client, data)
      @client = client
      super(data)
    end

    def to_s
      "#<#{self.class.name} time='#{time}' (#{data.size} values)>"
    end

    def inspect
      to_s
    end

    def time
      Time.at(ts)
    end

    private

    def method_missing(symbol, *args)
      return Time.at(data[symbol.to_s]) if symbol == :ts || symbol.to_s.end_with?('_at')
      return client.convert(symbol, super) if data.include?(symbol.to_s)

      super
    end

    def respond_to_missing?(symbol, include_private = false)
      return true if symbol == :ts || symbol.to_s.end_with?('_at')

      super
    end
  end
end
