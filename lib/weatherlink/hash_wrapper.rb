# frozen_string_literal: true

require 'delegate'

module WeatherLink
  class HashWrapper < SimpleDelegator
    attr_reader :data

    def initialize(data)
      @data = data
      super
    end

    private

    def method_missing(symbol, *args)
      return data.fetch(symbol.to_s) if data.include?(symbol.to_s)

      super
    end

    def respond_to_missing?(symbol, include_private = false)
      return true if data.include?(symbol.to_s)

      super
    end
  end
end
