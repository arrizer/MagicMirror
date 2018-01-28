Request = require 'request'
Async = require 'async'

module.exports = (server) =>
  log = server.log

  loadObjects = (values, next) ->
    valuesParameter = values.map((value) -> encodeURIComponent(value)).join(',')
    request =
      url: "#{server.config.baseURL}/get/#{valuesParameter}/?prettyPrint"
      json: yes
    log.debug("Loading objects: #{request.url}")
    Request request, (error, response, body) ->
      if error?
        log.error("Error loading objects #{request.url}: #{error}")
        return next(error)
      result = {}
      for item in body
        result[item._id] = item
      next(null, result)

  views =
    openWindows: (config, next) ->
      values = []
      for name,value of config.objects
        values.push(value)
      loadObjects values, (error, values) ->
        return next(error) if error?
        data = {}
        for name,value of config.objects
          data[name] = values[value].val
        next(null, data)

  server.handle 'views', (query, respond, fail) ->
    Async.map server.config.views, (config, done) ->
      handler = views[config.view]
      result = {}
      result.view = config.view
      if handler?
        handler config, (error, data) ->
          if error?
            result.error = error.toString() 
          else
            result.data = data
          done(null, result)
      else
        result.error = "Unknown view '#{config.view}'"
        done(null, result)
    , (error, views) ->
      respond(views)