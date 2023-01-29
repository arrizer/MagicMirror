XMLRPC = require 'xmlrpc'

module.exports = (server) =>
  log = server.log
  client = XMLRPC.createClient(host: server.config.ccuHost, port: 2001, path: '/')

  getValue = (address, key) ->
    new Promise (resolve, reject) ->
      server.log.debug "Getting value #{address} #{key}"
      client.methodCall 'getValue', [address, key], (error, response) ->
        return reject(error) if error?
        resolve(response)

  views =
    openWindows: (config) ->
      values = []
      for name,value of config.objects
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
      for name,value of config.objects
        if Array.isArray(value)
          data[name] = false
          for subvalue in value
            data[name] = true if results[subvalue]
        else
          data[name] = results[value]
      return data

  server.handle 'views', (query) ->
    results = []
    for config in server.config.views
      handler = views[config.view]
      result = {}
      result.view = config.view
      if handler?
        try
          result.data = await handler(config)
        catch error
          result.error = error.toString()
      else
        result.error = "Unknown view '#{config.view}'"
      results.push(result)
    return results