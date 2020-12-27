# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'json'

module WeatherLink
  class APIv2
    BASE_URI = 'https://api.weatherlink.com/v2'

    SYSTEM_TYPES = {
      Legacy: SystemType.new(name: 'Legacy'),
      EnviroMonitor: SystemType.new(name: 'EnviroMonitor'),
      WeatherLinkLive: SystemType.new(name: 'WeatherLink Live'),
      AirLink: SystemType.new(name: 'AirLink'),
    }.freeze

    RECORD_TYPES = [
      RecordType.new(
        id: 1,
        system: SYSTEM_TYPES[:Legacy],
        name: 'Current Conditions Record - Revision A',
        type: :current_conditions
      ),
      RecordType.new(
        id: 2,
        system: SYSTEM_TYPES[:Legacy],
        name: 'Current Conditions Record - Revision B',
        type: :current_conditions
      ),
      RecordType.new(
        id: 3,
        system: SYSTEM_TYPES[:Legacy],
        name: 'Archive Record - Revision A',
        type: :archive
      ),
      RecordType.new(
        id: 4,
        system: SYSTEM_TYPES[:Legacy],
        name: 'Archive Record - Revision B',
        type: :archive
      ),
      RecordType.new(
        id: 5,
        system: SYSTEM_TYPES[:Legacy],
        name: 'High/Low Record (deprecated)',
        type: :high_low
      ),
      RecordType.new(
        id: 6,
        system: SYSTEM_TYPES[:EnviroMonitor],
        name: 'ISS Current Conditions Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 7,
        system: SYSTEM_TYPES[:EnviroMonitor],
        name: 'ISS Archive Record',
        type: :archive
      ),
      RecordType.new(
        id: 8,
        system: SYSTEM_TYPES[:EnviroMonitor],
        name: 'ISS High/Low Record (deprecated)',
        type: :archive
      ),
      RecordType.new(
        id: 9,
        system: SYSTEM_TYPES[:EnviroMonitor],
        name: 'non-ISS Record',
        type: :unknown
      ),
      RecordType.new(
        id: 10,
        system: SYSTEM_TYPES[:WeatherLinkLive],
        name: 'ISS Current Conditions Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 11,
        system: SYSTEM_TYPES[:WeatherLinkLive],
        name: 'ISS Archive Record',
        type: :archive
      ),
      RecordType.new(
        id: 12,
        system: SYSTEM_TYPES[:WeatherLinkLive],
        name: 'non-ISS Current Conditions Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 13,
        system: SYSTEM_TYPES[:WeatherLinkLive],
        name: 'non-ISS Archive Record',
        type: :archive
      ),
      RecordType.new(
        id: 14,
        system: SYSTEM_TYPES[:EnviroMonitor],
        name: 'Health Record',
        type: :health
      ),
      RecordType.new(
        id: 15,
        system: SYSTEM_TYPES[:WeatherLinkLive],
        name: 'Health Record',
        type: :health
      ),
      RecordType.new(
        id: 16,
        system: SYSTEM_TYPES[:AirLink],
        name: 'Current Conditions Record',
        type: :current_conditions
      ),
      RecordType.new(
        id: 17,
        system: SYSTEM_TYPES[:AirLink],
        name: 'Archive Record',
        type: :archive
      ),
      RecordType.new(
        id: 18,
        system: SYSTEM_TYPES[:AirLink],
        name: 'Health Record',
        type: :health
      ),
    ].freeze

    RECORD_TYPES_BY_ID = RECORD_TYPES.each_with_object({}) { |r, h| h[r.id] = r }

    def self.record_type(id)
      RECORD_TYPES_BY_ID[id]
    end

    # TODO: Eliminate duplicate data e.g. rain_rate_last_{in,mm,clicks}
    # TODO: Wind speeds are actually in mph not m/s?
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

    attr_reader :api_key, :api_secret, :units

    def initialize(api_key:, api_secret:, units: IMPERIAL_WEATHER_UNITS)
      @api_key = api_key
      @api_secret = api_secret
      @units = units
    end

    def type_for(field)
      return nil unless [String, Symbol].include?(field.class)

      RECORD_FIELD_UNITS.fetch(field.to_sym, nil)
    end

    def unit_for(field)
      units.fetch(type_for(field))
    end

    def sensor_catalog
      request(path: 'sensor-catalog')
    end

    def stations(ids = nil)
      request(path: 'stations', path_params: { 'station-ids' => optional_array_param(ids) })
    end

    alias station stations

    def nodes(ids = nil)
      request(path: 'nodes', path_params: { 'node-ids' => optional_array_param(ids) })
    end

    alias node nodes

    def sensors(ids = nil)
      request(path: 'sensors', path_params: { 'sensor-ids' => optional_array_param(ids) })
    end

    alias sensor sensors

    def sensor_activity(ids = nil)
      request(path: 'sensor-activity', path_params: { 'sensor-ids' => optional_array_param(ids) })
    end

    def current(id)
      request(path: 'current', path_params: { 'station-id' => id })
    end

    def historic(id, start_timestamp, end_timestamp)
      request(
        path: 'historic',
        path_params: { 'station-id' => id },
        query_params: { 'start-timestamp' => start_timestamp, 'end-timestamp' => end_timestamp }
      )
    end

    def last_seconds(id, seconds)
      historic(id, Time.now.to_i - seconds, Time.now.to_i)
    end

    def last_hour(id)
      last_seconds(id, 3600)
    end

    def last_day(id)
      last_seconds(id, 86_400)
    end

    def request(path:, path_params: {}, query_params: {})
      uri = request_uri(path: path, path_params: path_params, query_params: query_params)
      response = Net::HTTP.get_response(uri)
      JSON.parse(response.body)
    end

    def request_uri(path:, path_params: {}, query_params: {})
      used_path_params = path_params.compact

      request_params = query_params.merge({ 't' => Time.now.to_i, 'api-key' => api_key })
      request_params.merge!(
        {
          'api-signature' => api_signature(path_params: used_path_params, query_params: request_params),
        }
      )

      uri = ([BASE_URI, path] + Array(used_path_params.values)).compact.join('/')

      URI("#{uri}?#{URI.encode_www_form(request_params)}")
    end

    # private

    def optional_array_param(param)
      param.is_a?(Array) ? param.join(',') : param
    end

    def stuffed_params(params)
      params.sort_by { |k, _| k }.map { |k, v| k.to_s + v.to_s }.join
    end

    def api_signature(path_params: {}, query_params: {})
      OpenSSL::HMAC.hexdigest('SHA256', api_secret, stuffed_params(path_params.merge(query_params)))
    end
  end
end
