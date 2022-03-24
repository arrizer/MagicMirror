(widget) ->
  container = widget.div.find('.container')
  container.text widget.string("loading")

  CURRENCY_SYMBOLS =
    EUR: '€'
    USD: '$'

  widget.loadPeriodic 'quotes', 60 * 5, (error, items) ->
    container.empty()
    if error?
      container.text(error)
      return
    for item in items
      itemEl = $('<div>').addClass('item').appendTo(container)
      $('<div>').addClass('title').text(item.title).appendTo(itemEl)
      quotesEl = $('<div>').addClass('quotes').appendTo(itemEl)
      currency = CURRENCY_SYMBOLS[item.currency] or item.currency
      $('<div>').addClass('price').text("#{widget.util.formatNumber(item.price, (maximumFractionDigits: 2, minimumFractionDigits: 2))} #{currency}").appendTo(quotesEl)
      for quote in item.quotes
        quoteEl = $('<div>').addClass('quote').appendTo(quotesEl)
        quoteEl.addClass("trend_#{quote.trend}")
        $('<div>').addClass('trend').text(if quote.trend is 'up' then '▲' else '▼').appendTo(quoteEl)
        $('<div>').addClass('change').text("#{widget.util.formatNumber(quote.change, (maximumFractionDigits: 2, minimumFractionDigits: 2))} %").appendTo(quoteEl)
        $('<div>').addClass('range').text(widget.string("quote.#{quote.range}")).appendTo(quoteEl)