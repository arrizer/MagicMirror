Request = require 'request'

module.exports = (server) =>
  log = server.log
    
  server.init = (next) ->
    next()
    
  server.handle 'forecast', (query, respond, fail) ->
    request =
      url: "https://api.forecast.io/forecast/#{server.config.forecast_api_key}/#{server.config.latitude},#{server.config.longitude}?units=#{server.config.units}"
      json: yes
    Request request, (error, response, body) ->
      return fail(error) if error?
      respond(body)