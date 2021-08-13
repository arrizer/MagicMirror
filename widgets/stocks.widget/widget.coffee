(widget) ->
  container = widget.div.find('.container')

  widget.init = ->
    container.text widget.string("loading")
    refresh()
    setInterval refresh, 1000 * 60 * 5

  refresh = ->
    widget.load 'quotes', (error, items) ->
      container.empty()
      if error?
        container.text(error)
        setTimeout refresh, 1000
        return
      for item in items
        itemEl = $('<div>').addClass('item').appendTo(container)
        $('<div>').addClass('title').text(item.title).appendTo(itemEl)
        quotesEl = $('<div>').addClass('quotes').appendTo(itemEl)
        for quote in item.quotes
          quoteEl = $('<div>').addClass('quote').appendTo(quotesEl)
          quoteEl.addClass("trend_#{quote.trend}")
          $('<div>').addClass('trend').text(if quote.trend is 'up' then '▲' else '▼').appendTo(quoteEl)
          $('<div>').addClass('change').text("#{widget.util.formatNumber(quote.change, (maximumFractionDigits: 2, minimumFractionDigits: 2))} %").appendTo(quoteEl)
          $('<div>').addClass('range').text(widget.string("quote.#{quote.range}")).appendTo(quoteEl)