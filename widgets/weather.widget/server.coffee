Request = require 'request'

module.exports = (server) =>
  log = server.log
    
  server.init = (next) ->
    next()
    
  server.handle 'forecast', (query, respond, fail) ->
    request =
      url: "http://api.wunderground.com/api/#{server.config.wunderground_api_key}/geolookup/conditions/forecast10day/q/#{server.config.country}/#{server.config.city}.json"
      json: yes
    Request request, (error, serverResponse, body) ->
      return fail(error) if error?
      return fail("Wunderground API Error: #{serverResponse.error.description}") if serverResponse.error?
      units = server.config.units
      days = body.forecast.simpleforecast.forecastday[ .. 6].map (day) ->
        item =
          date: parseInt(day.date.epoch)
          conditions: day.icon
          temperatureHigh: parseInt(day.high[units])
          temperatureLow: parseInt(day.low[units])
        return item
      response =
        units: server.config.units
        days: days
      respond(response)