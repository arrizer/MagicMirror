module.exports = (server) =>
  log = server.log
        
  server.handle 'departures', (query) ->
    config = server.config
    results = []
    for station in config.stations
      body = await server.http.getJSON "http://www.mvg-live.de/serviceV1/departures/#{encodeURIComponent(station.station)}/json?apiKey=#{config.mvglive_api_key}&maxEntries=50"
      throw new Error("Unexpected API response: #{JSON.stringify(body)}") unless body.mvgLiveResponse? and body.mvgLiveResponse.departures?
      result =
        station: station.station
        walkingDistanceMinutes: station.walkingDistanceMinutes
        departures: body.mvgLiveResponse.departures
      results.push(result)
    return results