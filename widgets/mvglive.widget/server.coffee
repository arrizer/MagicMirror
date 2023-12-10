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
API_KEY = '6y5ND70iERyaZ'

module.exports = (server) =>
  log = server.log

  stations = []

  performAPIRequest = (endpoint, query) ->
    query = new URLSearchParams(query).toString()
    return await server.http.request
      url: "https://fahrinfo-backend-prod.web.azrapp.swm.de/rest/v2/#{endpoint}?#{query}"
      headers:
        'Api_key': API_KEY
      responseContentType: 'json'

  findStationID = (query) ->
    log.info "Finding stationID for '#{query}'"
    results = await performAPIRequest('location', (query: query, locationTypes: 'STATION'))
    for result in results
      if result.globalId?
        return result.globalId
    throw new Error("Did not find a station for query: '#{query}'")

  setup = ->
    return if stations.length > 0
    for item in server.config.stations
      throw new Error("Missing 'station' parameter in config") unless item.station?
      item.stationID = await findStationID(item.station) unless item.stationID?
      stations.push(item)

  server.handle 'departures', (query) ->
    await setup()
    config = server.config
    results = []
    for station in stations
      body = await performAPIRequest('departure', (globalId: station.stationID))
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
