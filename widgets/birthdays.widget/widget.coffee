(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')
    
    refresh = ->
      widget.load 'birthdays', (error, response) ->
        container.empty()
        if error?
          widget.div.show()
          container.text(error)
          return
        unless response.hasInitialData
          widget.div.hide()
          setTimeout (-> refresh()), 1000
          return
        for birthday in response.birthdays
          text = birthday.name
          text += " (#{birthday.age})" if birthday.age?
          div = $('<div/>').addClass('birthday').appendTo(container)
          if birthday.days > 0
            div.addClass('upcoming')
            if birthday.days == 1
              text += " " + widget.string("tomorrow")
            else
              text += " " + widget.string("daysAhead", birthday.days)
          $('<img/>').addClass('icon').attr('src', "/birthdays/resources/birthday.png").appendTo(div)
          name = $('<div/>').addClass('name').text(text).appendTo(div)
          
        if response.birthdays.length > 0
          widget.div.show()
        else
          widget.div.hide()
        setTimeout (-> refresh()), (1000 * 60)

    widget.div.hide()
    refresh()