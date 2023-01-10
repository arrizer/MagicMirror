module.exports = (server) =>
  log = server.log

  loadObjects = (values) ->
    valuesParameter = values.map((value) -> encodeURIComponent(value)).join(',')
    body = await server.http.getJSON("#{server.config.baseURL}/get/#{valuesParameter}/?prettyPrint")
    result = {}
    for item in body
      result[item._id] = item
    return result

  views =
    openWindows: (config) ->
      objects = []
      for name,value of config.objects
        if Array.isArray(value)
          objects = objects.concat(value)
        else
          objects.push(value)
      values = await loadObjects(objects)
      data = {}
      for name,value of config.objects
        if Array.isArray(value)
          data[name] = false
          for subvalue in value
            data[name] = true if values[subvalue].val
        else
          data[name] = values[value].val
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