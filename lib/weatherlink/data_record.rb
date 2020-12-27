# frozen_string_literal: true

module WeatherLink
  class DataRecord < HashWrapper
    attr_reader :client

    def initialize(client, data)
      @client = client
      super(data)
    end
  end
end
