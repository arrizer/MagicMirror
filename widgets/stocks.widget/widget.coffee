(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')

    refresh = ->
      widget.load 'quotes', (error, items) ->
        container.empty()
        if error?
          container.text(error)
          setTimeout (-> refresh()), 1000 * 10
          return
        for item in items
          itemEl = $('<div>').addClass('item').appendTo(container)
          $('<div>').addClass('title').text(item.title).appendTo(itemEl)
          quotesEl = $('<div>').addClass('quotes').appendTo(itemEl)
          for quote in item.quotes
            quoteEl = $('<div>').addClass('quote').appendTo(quotesEl)
            quoteEl.addClass("trend_#{quote.trend}")
            $('<div>').addClass('trend').text(if quote.trend is 'up' then '▲' else '▼').appendTo(quoteEl)
            $('<div>').addClass('change').text(quote.change).appendTo(quoteEl)
            $('<div>').addClass('range').text(widget.string("quote.#{quote.range}")).appendTo(quoteEl)
        setTimeout (-> refresh()), (1000 * 60 * 5)

    container.text widget.string("loading")
    refresh()