Request = require 'request'
Util = require 'util'

BASE_URL = 'https://api.netatmo.net'

module.exports = (server) =>
  log = server.log
  tokens = null

  units =
    'Temperature': '°C'
    'Humidity': '%'
    'CO2': 'ppm'
    'Noise': 'db'
    'Pressure': 'mBar'

  metricsFromDashboardData = (data) ->
    return [] unless data?
    keys = ['Temperature', 'CO2', 'Humidity']
    metrics = []
    for key in keys when data[key]?
      value = data[key]
      metric =
        type: key
        value: value
        unit: units[key]
      if key is 'CO2'
        if value <= 1000
          metric.quality = 'good'
        else if value <= 1500
          metric.quality = 'fair'
        else if value <= 2000
          metric.quality = 'inferior'
        else
          metric.quality = 'bad'
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

  authenticate = (next) ->
    if tokens? 
      if tokens.accessTokenExpiration < (new Date())
        log.debug "Access token is expired"
        tokens.accessToken = null
      else
        return next(null, tokens.accessToken)
    form = {}
    if tokens? and tokens.refreshToken?
      log.info "Refreshing access token with refresh token"
      form =
        client_id: server.config.auth.client_id
        client_secret: server.config.auth.client_secret
        refresh_token: tokens.refreshToken
        grant_type: 'refresh_token'
    else
      log.info "Obtaining refresh token with credentials"
      form =
        client_id: server.config.auth.client_id
        client_secret: server.config.auth.client_secret
        username: server.config.auth.username
        password: server.config.auth.password
        scope: 'read_station'
        grant_type: 'password'
    request = 
      url: "#{BASE_URL}/oauth2/token"
      method: 'POST'
      form: form
      json: yes
    Request request, (error, response, body) ->
      return next(error) if error?
      return next(new Error("Authentication failed: HTTP #{response.statusCode}")) if response.statusCode != 200
      now = new Date()
      tokens = {} unless tokens?
      tokens.accessToken = body.access_token
      tokens.refreshToken = body.refresh_token
      tokens.accessTokenExpiration = new Date(now.getTime() + (body.expires_in * 1000))
      next(null, tokens.accessToken)

  getStationsData = (next) ->
    authenticate (error, accessToken) ->
      return next(error) if error?
      log.info "Getting stations data"
      request = 
        url: "#{BASE_URL}/api/getstationsdata"
        form: (access_token: accessToken)
        json: yes
        method: 'POST'
      Request request, (error, response, body) ->
        return next(error) if error?
        return next(new Error("Unexpected response")) unless body.body.devices?
        next(null, body.body.devices)

  server.handle 'stations', (query, respond, fail) ->
    getStationsData (error, devices) ->
      return fail(error) if error?
      devices = devices.filter((device) -> server.config.stations.indexOf(device.station_name) isnt -1)
      return fail("No devices found") if devices.length == 0
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
      respond(stations)