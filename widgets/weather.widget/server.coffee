JWT = require 'jsonwebtoken'

module.exports = (server) =>
  log = server.log
  config = server.config
  token = null

  server.init = ->
    key = config.authorization
    payload =
      iss: key.teamID
      sub: key.serviceID
    options =
      algorithm: 'ES256'
      keyid: key.keyID
      header: 
        id: "#{key.teamID}.#{key.serviceID}"
    JWT.sign payload, key.privateKey, options, (error, result) ->
      throw error if error?
      token = result
        
  server.handle 'forecast', (query) ->
    request =
      method: 'GET'
      url: "https://weatherkit.apple.com/api/v1/weather/#{config.country}/#{config.latitude}/#{config.longitude}?dataSets=forecastDaily"
      responseContentType: 'json'
      headers:
        'Authorization': "Bearer #{token}"
    body = await server.http.request(request)
    throw new Error("WeatherKit API Error: #{body}") if body.error?
    days = body.forecastDaily.days[ .. 6].map (day) ->
      item =
        date: Date(day.forecastStart)
        icon: day.conditionCode
        temperatureHigh: Math.round(day.temperatureMax)
        temperatureLow: Math.round(day.temperatureMin)
        precipitationProbability: Math.round(day.precipitationChance * 100)
      return item
    response =
      units: server.config.units
      days: days
    return response