Request = require 'request'

icons =
  'clear-day': 'sunny'
  'clear-night': 'sunny'
  'rain': 'rain'
  'snow': 'snow'
  'sleet': 'sleet'
  'wind': 'wind'
  'fog': 'fog'
  'cloudy': 'cloudy'
  'partly-cloudy-day': 'partly-cloudy'
  'partly-cloudy-night': 'partly-cloudy'

module.exports = (server) =>
  log = server.log
    
  server.init = (next) ->
    next()
    
  server.handle 'forecast', (query, respond, fail) ->
    units = if server.config.units == 'celsius' then 'si' else 'us'
    request =
      url: "https://api.darksky.net/forecast/#{server.config.darksky_api_key}/#{server.config.latitude},#{server.config.longitude}?units=#{units}"
      json: yes
    Request request, (error, serverResponse, body) ->
      return fail(error) if error?
      return fail("DarkSky API Error: #{serverResponse}") if serverResponse.error?
      days = body.daily.data[ .. 6].map (day) ->
        item =
          date: parseInt(day.time)
          icon: icons[day.icon]
          temperatureHigh: Math.round(day.temperatureMax)
          temperatureLow: Math.round(day.temperatureMin)
          precipitationProbability: Math.round(day.precipProbability * 100)
        return item
      response =
        units: server.config.units
        days: days
      respond(response)