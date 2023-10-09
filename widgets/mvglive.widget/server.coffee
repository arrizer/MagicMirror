LINE_COLORS =
  'U1': '#438136'
  'U2': '#C40C37'
  'U3': '#F36E31'
  'U4': '#0AB38D'
  'U5': '#B8740E'
  'U6': '#006CB3'
  'U7': '#438136'
  'U8': '#a90c37'
  'S1': '#16bae7'
  'S2': '#76b82A'
  'S3': '#951B81'
  'S4': '#E30613'
  'S6': '#00975F'
  'S7': '#943126'
  'S8': '#000000'
  'S20': '#ED6B83'

MAX_DEPARTURE = 2 * 60 * 60 * 1000 # 2 hours

module.exports = (server) =>
  log = server.log

  stations = []

  findStationID = (query) ->
    log.info "Finding stationID for '#{query}'"
    results = await server.http.getJSON "https://www.mvg.de/api/fib/v2/location?query=#{encodeURIComponent(query)}"
    for result in results
      if result.type is 'STATION'
        return result.globalId
    throw new Error("Did not find a station for query: '#{query}'")

  server.init = ->
    for item in server.config.stations
      throw new Error("Missing 'station' parameter in config") unless item.station?
      item.stationID = await findStationID(item.station) unless item.stationID?
      stations.push(item)

  server.handle 'departures', (query) ->
    config = server.config
    results = []
    for station in stations
      body = await server.http.getJSON "https://www.mvg.de/api/fib/v2/departure?globalId=#{station.stationID}&limit=20"
      now = new Date()
      body = body.filter (departure) -> 
        departureDate = new Date(parseInt(departure.realtimeDepartureTime))
        return (departureDate >= now) and ((departureDate - now) <= MAX_DEPARTURE)
      result =
        station: station.station
        walkingDistanceMinutes: station.walkingDistanceMinutes
        departures: body.map (departure) ->
          mapped =
            destination: departure.destination
            time: departure.realtimeDepartureTime
            line: departure.label
            color: LINE_COLORS[departure.label]
          return mapped
      results.push(result)
    return results
