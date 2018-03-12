Request = require 'request'
Async = require 'async'

module.exports = (server) =>
  log = server.log

  loadChart = (symbol, range, interval, next) ->
    request =
      url: "https://query1.finance.yahoo.com/v8/finance/chart/#{encodeURIComponent(symbol)}"
      qs:
        range: range
        interval: interval
        includePrePost: no
      json: yes
    Request request, (error, _, response) ->
      return next(error) if error?
      response = response.chart
      return next(new Error("Yahoo Finance API Error: #{response.error.code}: #{response.error.description}")) if response.error?
      result = response.result[0]
      previousClose = result.meta.previousClose
      quote = result.indicators.quote[0]
      openPrices = quote.open.filter((v) -> v?)
      closePrices = quote.close.filter((v) -> v?)
      chart =
        priceOpen: if range is '1d' and previousClose? then previousClose else openPrices[0]
        priceClose: closePrices[closePrices.length - 1]
      console.log symbol, range, chart
      chart.changePercentage = ((chart.priceClose / chart.priceOpen) - 1) * 100
      console.log chart
      next(null, chart)

  server.handle 'quotes', (query, respond, fail) ->
    ranges = [
      (key: '1day', range: '1d', interval: '1m'),
      (key: '5days', range: '5d', interval: '1m'),
      (key: '1month', range: '1mo', interval: '1d')
    ]
    Async.map server.config.quotes, (quote, done) ->
      log.info "Loading stock quote for #{quote.title} [#{quote.symbol}]"
      Async.map ranges, (range, done) ->
        loadChart quote.symbol, range.range, range.interval, (error, chart) ->
          return next(error) if error?
          roundedChange = Math.round(chart.changePercentage * 100) / 100
          result =
            range: range.key
            change: parseFloat(Math.round(roundedChange * 100) / 100).toFixed(2) + ' %'
            open: chart.priceOpen
            close: chart.priceClose
            trend: if chart.changePercentage >= 0 then 'up' else 'down'
          done(null, result)
      , (error, results) ->
        return done(error) if error?
        result =
          title: quote.title
          symbol: quote.symbol
          quotes: results
        done(null, result)
    , (error, results) ->
      return fail(error) if error?
      respond(results)