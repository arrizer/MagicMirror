(widget) ->
  widget.init = (next) ->    
    container = widget.div.find('.container')
    
    refresh = ->
      widget.load 'todos', (error, todos) ->
        return if error?
        container.empty()
        for todo in todos
          div = $('<div></div>').addClass('todo').text('▢ ' + todo.title)
          div.addClass('today') if todo.today
          div.appendTo(container)
        
    container.text widget.string('loading')    
    refresh()
    setInterval ->
      refresh()
    , 5000