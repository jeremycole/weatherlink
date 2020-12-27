# frozen_string_literal: true

require 'net/http'
require 'json'

module WeatherLink
  class LocalAPIv1
    class RequestError < StandardError; end

    LOCAL_API = SystemType.new(name: 'Local API')

    RECORD_TYPES = [
      RecordType.new(
        id: 1,
        system: LOCAL_API,
        name: 'ISS Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 2,
        system: LOCAL_API,
        name: 'Leaf/Soil Moisture Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 3,
        system: LOCAL_API,
        name: 'LSS Barometric Pressure Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 4,
        system: LOCAL_API,
        name: 'LSS Temperature/Humidity Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 6,
        system: LOCAL_API,
        name: 'AirLink Record',
        type: :current_conditions
      ),
    ].freeze

    RECORD_TYPES_BY_ID = RECORD_TYPES.each_with_object({}) { |r, h| h[r.id] = r }

    def self.record_type(id)
      RECORD_TYPES_BY_ID[id]
    end

    RECORD_FIELD_UNITS = {
      temp: :temperature,
      temp_in: :temperature,
      dew_point: :temperature,
      dew_point_in: :temperature,
      wet_bulb: :temperature,
      heat_index: :temperature,
      heat_index_in: :temperature,
      wind_chill: :temperature,
      thw_index: :temperature,
      thsw_index: :temperature,
      hum: :humidity,
      hum_in: :humidity,
      bar_sea_level: :pressure,
      bar_absolute: :pressure,
      bar_trend: :pressure,
      wind_speed_last: :wind_speed,
      wind_speed_avg_last_1_min: :wind_speed,
      wind_speed_avg_last_2_min: :wind_speed,
      wind_speed_avg_last_10_min: :wind_speed,
      wind_speed_hi_last_2_min: :wind_speed,
      wind_speed_hi_last_10_min: :wind_speed,
      wind_dir_last: :wind_direction,
      wind_dir_scalar_avg_last_1_min: :wind_direction,
      wind_dir_scalar_avg_last_2_min: :wind_direction,
      wind_dir_scalar_avg_last_10_min: :wind_direction,
      wind_dir_at_hi_speed_last_2_min: :wind_direction,
      wind_dir_at_hi_speed_last_10_min: :wind_direction,
      rain_rate_last: :rain_rate,
      rain_rate_hi: :rain_rate,
      rain_rate_hi_last_15_min: :rain_rate,
      rainfall_last_15_min: :rain_quantity,
      rainfall_last_60_min: :rain_quantity,
      rainfall_last_24_hr: :rain_quantity,
      rainfall_daily: :rain_quantity,
      rainfall_monthly: :rain_quantity,
      rainfall_year: :rain_quantity,
      rain_storm: :rain_quantity,
      rain_storm_last: :rain_quantity,
      solar_rad: :solar_radiation,
    }.freeze

    attr_reader :host, :units

    def initialize(host:, units: IMPERIAL_WEATHER_UNITS)
      @host = host
      @units = units
    end

    def type_for(field)
      return nil unless [String, Symbol].include?(field.class)

      RECORD_FIELD_UNITS.fetch(field.to_sym, nil)
    end

    def unit_for(field)
      units.fetch(type_for(field))
    end

    def current_conditions
      request(path: 'current_conditions')
    end

    def request(path:, path_params: {}, query_params: {})
      uri = request_uri(path: path, path_params: path_params, query_params: query_params)
      response = Net::HTTP.get_response(uri)
      json_response = JSON.parse(response.body)
      raise RequestError, json_response['error'] if json_response['error']

      json_response['data']
    end

    def base_uri
      "http://#{host}/v1"
    end

    def request_uri(path:, path_params: {}, query_params: {})
      uri = ([base_uri, path] + Array(path_params.values)).compact.join('/')

      if query_params.none?
        URI(uri)
      else
        URI("#{uri}?#{URI.encode_www_form(query_params)}")
      end
    end

    # private

    def optional_array_param(param)
      param.is_a?(Array) ? param.join(',') : param
    end
  end
end
