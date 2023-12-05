module.exports = (server) =>
  log = server.log
  tokens = null

  BASE_URL = 'https://api.netatmo.net'

  keys = ['Temperature', 'CO2', 'Humidity', 'sum_rain_1', 'sum_rain_24', 'WindStrength', 'WindAngle', 'GustStrength']

  units =
    'Temperature': '°C'
    'Humidity': '%'
    'CO2': 'ppm'
    'Noise': 'db'
    'Pressure': 'mBar'
    'sum_rain_1': 'mm/h'
    'sum_rain_24': 'mm'
    'WindStrength': 'km/h'
    'WindAngle': '°'
    'GustStrength': 'km/h'
    'GustAngle': '°'

  metricsFromDashboardData = (data) ->
    return [] unless data?
    metrics = []
    for key in keys when data[key]?
      value = data[key]
      metric =
        type: key
        value: value
        unit: units[key]
      if key is 'CO2'
        if value <= 800
          metric.quality = 1
        else if value >= 2000
          metric.quality = 0
        else
          metric.quality = 1 - ((value - 800) / (2000 - 800))
      metrics.push(metric)
    return metrics

  stationFromObject = (object) ->
    moduleConfig = null
    for config in server.config.modules
      if config.module is object.module_name
        moduleConfig = config
    return null unless moduleConfig?
    station =
      module: object.module_name
      name: moduleConfig.title
      metrics: metricsFromDashboardData(object.dashboard_data)
    return station

  authenticate = ->
    if tokens? 
      if tokens.accessTokenExpiration < (new Date())
        log.debug "Access token is expired"
        tokens.accessToken = null
      else
        return tokens.accessToken
    form = {}
    if tokens? and tokens.refreshToken?
      log.info "Refreshing access token with refresh token"
      form =
        client_id: server.config.auth.client_id
        client_secret: server.config.auth.client_secret
        refresh_token: tokens.refreshToken
        grant_type: 'refresh_token'
    else
      log.info "Using refresh token from configuration or storage"
      form =
        client_id: server.config.auth.client_id
        client_secret: server.config.auth.client_secret
        refresh_token: server.storage.get('refreshToken') or server.config.auth.refresh_token
        grant_type: 'refresh_token'
    body = await server.http.postForm("#{BASE_URL}/oauth2/token", form)
    now = new Date()
    console.log body
    tokens = {} unless tokens?
    tokens.accessToken = body.access_token
    tokens.refreshToken = body.refresh_token
    tokens.accessTokenExpiration = new Date(now.getTime() + (body.expires_in * 1000))
    server.storage.set('refreshToken', tokens.refreshToken)
    return tokens.accessToken

  getStationsData = ->
    accessToken = await authenticate()
    log.info "Getting stations data"
    form = (access_token: accessToken)
    body = await server.http.postForm("#{BASE_URL}/api/getstationsdata", form)
    throw new Error("Unexpected response") unless body.body.devices?
    return body.body.devices

  server.handle 'stations', (query) ->
    devices = await getStationsData()
    devices = devices.filter((device) -> server.config.stations.indexOf(device.station_name) isnt -1)
    throw new Error("No devices found") if devices.length == 0
    stations = []
    for device in devices
      station = stationFromObject(device)
      stations.push(station) if station?
      for module in device.modules
        station = stationFromObject(module)
        stations.push(station) if station?
    orderedStations = []
    for moduleConfig in server.config.modules
      for station in stations
        if station.module is moduleConfig.module
          orderedStations.push(station)
    stations = orderedStations
    return stations
