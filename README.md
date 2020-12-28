# WeatherLink

This is an unofficial implementation of the Davis Instruments WeatherLink API, including both the Local API (v1) and the web API (v2).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'weatherlink'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install weatherlink

## Usage

### Local API

To read the data from a local WeatherLink Live device via the "local API" (there is no authentication):

```
require 'weatherlink'

> wl = WeatherLink::LocalClient.new(host: '<local ip address>')
```

The `current_conditions` method returns a `SensorData` object for each sensors: 

```
> cc = wl.current_conditions
=> #<WeatherLink::SensorDataCollection (3 sensors)>

> cc.to_a
=> [#<WeatherLink::SensorData lsid=1 (Local API - ISS Record, 1 records)>,
    #<WeatherLink::SensorData lsid=2 (Local API - LSS Temperature/Humidity Record, 1 records)>, 
    #<WeatherLink::SensorData lsid=3 (Local API - LSS Barometric Pressure Record, 1 records)>]
```

Each `SensorData` is a wrapper for a hash containing the underlying data. Each of its keys can also be used as a method to get the data itself.

```
> pp cc[0].to_h
{"ts"=>1609130694,
  "temp"=>24.2 tempF,
  "hum"=>84.9 %,
  "dew_point"=>20.3 tempF,
  "wet_bulb"=>22.6 tempF,
  "heat_index"=>24.2 tempF,
  "wind_chill"=>24.2 tempF,
  "thw_index"=>24.2 tempF,
  "thsw_index"=>22.2 tempF,
  "wind_speed_last"=>0 mph,
  "wind_dir_last"=>0 deg,
  "wind_speed_avg_last_1_min"=>0 mph,
  "wind_dir_scalar_avg_last_1_min"=>149 deg,
  "wind_speed_avg_last_2_min"=>0 mph,
  "wind_dir_scalar_avg_last_2_min"=>149 deg,
  "wind_speed_hi_last_2_min"=>1 mph,
  "wind_dir_at_hi_speed_last_2_min"=>149 deg,
  "wind_speed_avg_last_10_min"=>0 mph,
  "wind_dir_scalar_avg_last_10_min"=>149 deg,
  "wind_speed_hi_last_10_min"=>1 mph,
  "wind_dir_at_hi_speed_last_10_min"=>149 deg,
  "rain_size"=>1,
  "rain_rate_last"=>0 in/h,
  "rain_rate_hi"=>0 in/h,
  "rainfall_last_15_min"=>0 in,
  "rain_rate_hi_last_15_min"=>0 in/h,
  "rainfall_last_60_min"=>0 in,
  "rainfall_last_24_hr"=>0 in,
  "rain_storm"=>0 in,
  "rain_storm_start_at"=>nil,
  "solar_rad"=>0 W/m^2,
  "uv_index"=>0.0,
  "rx_state"=>0,
  "trans_battery_flag"=>0,
  "rainfall_daily"=>0 in,
  "rainfall_monthly"=>18 in,
  "rainfall_year"=>128 in,
  "rain_storm_last"=>5 in,
  "rain_storm_last_start_at"=>1608224100,
  "rain_storm_last_end_at"=>1608318061}
```

Note that the unit support uses `ruby-units` which uses `Rational`, so some of the results can be... interesting:

```
> cc[0].temp
=> -3342515348439043/791648371998720 tempC
```

Use `scalar.to_f` to get a `Float` most of the time:

```
> cc[0].temp.scalar.to_f
=> -4.222222222222226
```

### Web API

Obtain API credentials form your WeatherLink account and initialize the API:

```
require 'weatherlink'

> wl = WeatherLink::Client.new(api_key: '<api key>', api_secret: '<api secret>')
```

Various aspects of the API and devices can be interrogated:

```
> wl.stations
=> [#<WeatherLink::Station station_id=1 gateway_id_hex=a (Jackalope)>]

> wl.sensors
=> [#<WeatherLink::Sensor lsid=1 (Davis Instruments - WeatherLink LIVE Health)>,
    #<WeatherLink::Sensor lsid=2 (Davis Instruments - Barometer)>,
    #<WeatherLink::Sensor lsid=3 (Davis Instruments - Inside Temp/Hum)>,
    #<WeatherLink::Sensor lsid=4 (Davis Instruments - Vantage Pro2 Plus /w 24-hr-Fan-Aspirated Radiation shield, UV & Solar Radiation Sensors)>,
    #<WeatherLink::Sensor lsid=5 (Davis Instruments - AQS Health)>,
    #<WeatherLink::Sensor lsid=6 (Davis Instruments - AirLink)>,
    #<WeatherLink::Sensor lsid=7 (Davis Instruments - AQS Health)>,
    #<WeatherLink::Sensor lsid=8 (Davis Instruments - AirLink)>,
    #<WeatherLink::Sensor lsid=9 (Davis Instruments - AQS Health)>,
    #<WeatherLink::Sensor lsid=10 (Davis Instruments - AirLink)>]

> wl.nodes
=> [#<WeatherLink::Node device_id_hex=a (Station - Barn)>,
    #<WeatherLink::Node device_id_hex=b (Station - Living Room)>,
    #<WeatherLink::Node device_id_hex=c (Station - Office)>]
```

Since most users will probably only have one station, a `station` method returns the first station for convenience:

```
wl.station
=> #<WeatherLink::Station station_id=1 gateway_id_hex=a (Station)>
```

To collect current weather data from all sensor of the first/primary station:

```
> wl.station.current
=> #<WeatherLink::SensorDataCollection (10 sensors)>
```

At this point accessing the underlying data is exactly the same as using the Local API above.

Since the station knows the IP addresses of each sensor, if you're on the local network you can also access these sensors directly through the `local_sensors` method (which uses the same `WeatherLink::LocalClient` API above, but automatically configures it for each known sensor):

```
> wl.station.local_sensors
=> [#<struct WeatherLink::Station::LocalSensor device=#<WeatherLink::Station station_id=1 gateway_id_hex=a (Station)>, host="1.2.3.4">,
    #<struct WeatherLink::Station::LocalSensor device=#<WeatherLink::Node device_id_hex=b (Station - Living Room)>, host="1.2.3.5">,
    #<struct WeatherLink::Station::LocalSensor device=#<WeatherLink::Node device_id_hex=c (Station - Office)>, host="1.2.3.6">,
    #<struct WeatherLink::Station::LocalSensor device=#<WeatherLink::Node device_id_hex=d (Station - Barn)>, host="1.2.3.7">]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jeremycole/weatherlink.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
