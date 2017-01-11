Request = require 'request'

module.exports = (server) =>
  log = server.log
    
  server.init = (next) ->
    next()
    
  server.handle 'forecast', (query, respond, fail) ->
    request =
      url: "http://api.wunderground.com/api/#{server.config.wunderground_api_key}/geolookup/conditions/forecast10day/q/#{server.config.country}/#{server.config.city}.json"
      json: yes
    Request request, (error, response, body) ->
      return fail(error) if error?
      return fail("Wunderground API Error: #{response.error.description}") if response.error?
      body.units = server.config.units
      respond(body)