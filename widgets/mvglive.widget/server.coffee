Request = require 'request'
Async = require 'async'

module.exports = (server) =>
  log = server.log
    
  server.init = (next) ->
    next()
    
  server.handle 'departures', (query, respond, fail) ->
    config = server.config
    Async.mapSeries config.stations, (station, done) ->
      request =
        url: "http://www.mvg-live.de/serviceV1/departures/#{encodeURIComponent(station.station)}/json?apiKey=#{config.mvglive_api_key}&maxEntries=50"
        json: yes
      Request request, (error, response, body) ->
        return done(error) if error?
        result =
          station: station.station
          walkingDistanceMinutes: station.walkingDistanceMinutes
          departures: body.mvgLiveResponse.departures
        done(null, result)
    , (error, results) ->
      return fail(error) if error?
      respond(results)