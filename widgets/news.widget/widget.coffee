(widget) ->
  widget.init = ->
    articles = []
    nextArticle = 0
    headline = widget.div.find('.headline')
    headline.css 
      'font-size': '30px'
      'text-align': 'center'
      'text-color': '#888'
    
    proceed = -> 
      if nextArticle >= articles.length
        update ->
          nextArticle = 0
          if articles.length is 0
            headline.css 'text-color', '#888'
            headline.text widget.string('news.empty')
            setTimeout proceed, 1000
          else
            proceed()
      else
        headline.fadeOut(1000)
        index = nextArticle
        setTimeout ->
          headline.text articles[index].title
          headline.fadeIn(1000)          
          headline.css 'text-color', '#888'
        , 990
        nextArticle++
        setTimeout (-> proceed()), 7000
    
    update = (next) ->
      widget.load 'articles', (name: 'Didder'), (error, response) ->
        if error?
          headline.text 'Error: ' + error
        else
          articles = response
        next()
    
    headline.text widget.string('news.loading')
    proceed()