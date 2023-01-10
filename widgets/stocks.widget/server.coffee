module.exports = (server) =>
  log = server.log

  loadChart = (symbol, range, interval) ->
    url = "https://query1.finance.yahoo.com/v8/finance/chart/#{encodeURIComponent(symbol)}?range=#{range}&interval=#{interval}&includePrePost=no"
    response = await server.http.getJSON(url)
    throw new Error("Yahoo Finance API Error: #{response.error.code}: #{response.error.description}") if response.error?
    response = response.chart
    result = response.result[0]
    previousClose = result.meta.previousClose
    quote = result.indicators.quote[0]
    openPrices = [if previousClose? then previousClose else 0]
    closePrices = [if previousClose? then previousClose else 0]
    if quote.open? and quote.close?
      openPrices = quote.open.filter((v) -> v?)
      closePrices = quote.close.filter((v) -> v?)
    chart =
      priceOpen: if range is '1d' and previousClose? then previousClose else openPrices[0]
      priceClose: closePrices[closePrices.length - 1]
      price: result.meta.regularMarketPrice
      currency: result.meta.currency
    chart.changePercentage = ((chart.priceClose / chart.priceOpen) - 1) * 100
    return chart

  server.handle 'quotes', (query) ->
    ranges = [
      (key: '5days', range: '5d', interval: '1m'),
      (key: '1month', range: '1mo', interval: '1d')
    ]
    results = []
    for quote in server.config.quotes
      log.info "Loading stock quote for #{quote.title} [#{quote.symbol}]"
      charts = []
      for range in ranges
        chart = await loadChart(quote.symbol, range.range, range.interval)
        result =
          range: range.key
          change: chart.changePercentage
          open: chart.priceOpen
          close: chart.priceClose
          price: chart.price
          currency: chart.currency
          trend: if chart.changePercentage >= 0 then 'up' else 'down'
        charts.push(result)      
      result =
        title: quote.title
        symbol: quote.symbol
        price: charts[0].price
        currency: charts[0].currency
        quotes: charts
      results.push(result)
    return results