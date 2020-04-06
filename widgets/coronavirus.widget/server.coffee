Request = require 'request'
Async = require 'async'

module.exports = (server) =>
  log = server.log
  config = server.config

  getToken = (next) ->
    Request (url: "https://coronavirus.app/map"), (error, response, body) ->
      return next(error) if error?
      auth =
        token: /data-a="(.*?)"/.exec(body)[1]
        header: /data-b="(.*?)"/.exec(body)[1]
        date: /data-c="(.*?)"/.exec(body)[1]
      next(null, auth)

  loadStats = (next) ->
    getToken (error, auth) ->
      return next(error) if error?
      headers = {}
      headers[auth.header] = auth.token
      headers['x-date-req'] = auth.date
      request = 
        url: "https://coronavirus.app/get-places"
        headers: headers
        json: yes
      Request request, (error, _, body) ->
        return next(error) if error?
        places = body.data
        items = []
        for placeConfig in config.places
          item =
            label: placeConfig.label
            infected: 0
            sick: 0
            dead: 0
            recovered: 0
          for place in places
            if place.country is placeConfig.country
              item.infected += place.infected
              item.sick += place.sick
              item.dead += place.dead
              item.recovered += place.recovered
          items.push(item)
        next(null, items)

  server.handle 'stats', (query, respond, fail) ->
    loadStats (error, items) ->
      if error?
        fail(error)
      else
        respond(items)