icons = [
  "sunny",
  "partly-cloudy",
  "partly-cloudy",
  "cloudy",
  "fog",
  "fog",
  "rain-light",
  "rain",
  "rain-heavy",
  "rain-light",
  "rain-heavy",
  "sleet",
  "sleet",
  "snow-light",
  "snow",
  "snow-heavy",
  "hail",
  "sun-rain",
  "rain-heavy",
  "sleet",
  "snow",
  "snow-light",
  "snow",
  "hail",
  "hail",
  "thunderstorm",
  "thunderstorm",
  "thunderstorm",
  "hail",
  "hail",
  "wind"
]

module.exports = (server) =>
  log = server.log
    
  server.handle 'forecast', (query) ->
    units = if server.config.units == 'celsius' then 'si' else 'us'
    body = await server.http.getJSON("https://app-prod-ws.warnwetter.de/v30/stationOverviewExtended?stationIds=#{server.config.stationID}")
    days = body[Object.keys(body)[0]].days[ .. 6].map (day) ->
      item =
        date: Math.round((new Date(day.dayDate)).getTime() / 1000.0)
        icon: icons[day.icon]
        temperatureHigh: Math.round(day.temperatureMax / 10.0)
        temperatureLow: Math.round(day.temperatureMin / 10.0)
        precipitationProbability: Math.round(day.precipitation)
      return item
    response =
      units: 'celsius'
      days: days
    return response