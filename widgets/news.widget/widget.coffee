(widget) ->
  widget.init = (next) ->
    widget.div.text("Loading...")
    widget.load 'greet', (name: 'Didder'), (error, response) ->
      if error?
        widget.div.text 'Error: ' + error
      else
        widget.div.text response