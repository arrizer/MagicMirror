XMLRPC = require 'xmlrpc'
OS = require 'os'

SERVER_PORT = 9999

module.exports = (server) =>
  log = server.log
  xmlrpcClient = XMLRPC.createClient(host: server.config.ccuHost, port: 2001, path: '/')
  xmlrpcServer = XMLRPC.createServer(port: 9999)
  cachedValues = {}

  xmlrpcServer.on 'NotFound', (method, params) ->
    server.log.error('Method ' + method + ' does not exist')
  xmlrpcServer.on 'system.multicall', (_, params, callback) ->
    callsPending = params[0].length
    for call in params[0]
      xmlrpcServer.emit call.methodName, null, call.params, ->
        callsPending--
        callback(null, {}) if callsPending == 0
  xmlrpcServer.on 'event', (_, params, callback) ->
    return unless params.length == 4
    address = params[1]
    key = params[2]
    value = params[3]
    cacheKey = "#{address}.#{key}"
    return unless cachedValues[cacheKey]?
    cachedValues[cacheKey] = value
    server.log.debug "Update: #{address}.#{key} = #{value}"
    callback(null, {})

  getValue = (address, key) ->
    new Promise (resolve, reject) ->
      cacheKey = "#{address}.#{key}"
      cachedValue = cachedValues[cacheKey]
      return resolve(cachedValue) if cachedValue?
      server.log.debug "Getting value #{address} #{key}"
      xmlrpcClient.methodCall 'getValue', [address, key], (error, value) ->
        return reject(error) if error?
        cachedValues[cacheKey] = value
        resolve(value)

  subscribe = ->
    new Promise (resolve, reject) ->
      url = "http://#{getNetworkAddress()}:#{SERVER_PORT}/"
      server.log.info("Subscribing to HomeMatic events at #{url}")
      xmlrpcClient.methodCall 'init', [url, "MagicMirror"], (error, response) ->
        if error?
          server.log.error("Failed to subscribe to HomeMatic: #{error}")
          return reject(error)
        else
          console.log(response)
          return resolve(response)

  getNetworkAddress = ->
    for name, ifaces of OS.networkInterfaces()
      for iface in ifaces
        continue if iface.internal
        continue unless iface.family is 'IPv4'
        return iface.address
    return null

  server.init = ->
    await subscribe()

  server.handle 'openWindows', (query) ->
    values = []
    for name,value of server.config.openWindows
      if Array.isArray(value)
        values = values.concat(value)
      else
        values.push(value)
    results = {}
    for value in values
      address = value.split('.')[0]
      key = value.split('.')[1]
      results[value] = await getValue(address, key)
    data = {}
    for name,value of server.config.openWindows
      if Array.isArray(value)
        data[name] = false
        for subvalue in value
          data[name] = true if results[subvalue]
      else
        data[name] = results[value]
    return data
