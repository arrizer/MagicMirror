$ -> 
  decode = (s) -> he.decode(s)

  class Dashboard
    constructor: (@dashboard) ->
      @widgets = []
   
    createWidget: (instance) ->
      container = $('<div></div>').addClass('widget_container').appendTo(@dashboard)
      template = $(decode $('#widget_' + instance.widget + '_template').text())
      template.appendTo(container)
      template.attr 'id', 'widget_instance_' + instance.instanceID
      template.addClass 'widget'
      template.addClass instance.widget
      errorOverlay = $('<div></div>').addClass('error_overlay').appendTo(container)
      errorOverlay.hide()
      strings = JSON.parse(decode $('#widget_' + instance.widget + '_strings').text())
      config = JSON.parse(decode $('#config').text())
      scheduledPeriodicLoad = null
      widget =
        div: template
        update: (next) -> next()
        string: (key, placeholders...) -> 
          string = strings[key]
          index = 1
          string = string.replace '%' + index++, placeholder for placeholder in placeholders
          return string
        config: instance.config
        util:
          formatNumber: (value, options) ->
            options = {} unless options?
            return Intl.NumberFormat(config.language, options).format(value)
        globalConfig: config
        loadPeriodic: (endpoint, seconds, next) ->
          done = (error) ->
            template.css('opacity', if !error? then '1' else '0.3')
            timeout = if !error? then seconds else 1
            errorOverlay.text(if error? then error.message else '')
            if error?
              errorOverlay.show()
            else
              errorOverlay.hide()
            clearTimeout(scheduledPeriodicLoad) if scheduledPeriodicLoad?
            scheduledPeriodicLoad = setTimeout (-> widget.loadPeriodic(endpoint, seconds, next)), 1000 * timeout
          widget.load endpoint, (error, response) ->
            if error?
              done(new Error("Load failed: #{error.message}"))
            else
              try
                next(null, response)
                done(null)
              catch error
                done(new Error("Client Error: #{error.message}"))
        load: (endpoint, next) ->
          next = (=>) unless next?
          fetch instance.instanceID + '/' + endpoint, (method: 'GET')
          .then (response) =>
            if response.ok
              response.json()
              .then (json) => 
                if json.success
                  next null, json.response
                else
                  next new Error("Server Error: #{json.error}")
              .catch (error) => 
                next new Error("JSON parser error: #{error.message}")
            else
              next new Error("HTTP Error: #{response.status} #{response.statusText}")
          .catch (error) =>
            next new Error("Network Error: #{error.message}")
      widgetFactories[instance.widget](widget)
      @widgets.push widget
  
  instances = JSON.parse(decode $('#widget_instances').text())
  dashboard = new Dashboard($('#dashboard'))
  dashboard.createWidget(instance) for instance in instances
