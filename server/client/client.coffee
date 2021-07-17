$ -> 
  decode = (s) -> s.replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&apos;/g,"'").replace(/&amp;/g,'&')

  class Dashboard
    constructor: (@dashboard) ->
      @widgets = []
   
    createWidget: (instance) ->
      template = $(decode $('#widget_' + instance.widget + '_template').text())
      template.attr 'id', 'widget_instance_' + instance.instanceID
      template.addClass 'widget'
      template.addClass instance.widget
      template.appendTo(@dashboard)
      strings = JSON.parse(decode $('#widget_' + instance.widget + '_strings').text())
      widget =
        div: template
        update: (next) -> next()
        string: (key, placeholders...) -> 
          string = strings[key]
          index = 1
          string = string.replace '%' + index++, placeholder for placeholder in placeholders
          return string
        config: instance.config
        globalConfig: JSON.parse(decode $('#config').text())
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
                  next new Error(json.error)
              .catch (error) => next error
            else
              next new Error("HTTP Error: #{response.status} #{response.statusText}")
          .catch (error) =>
            next error
      widgetFactories[instance.widget](widget)
      widget.init()
      @widgets.push widget
  
  instances = JSON.parse(decode $('#widget_instances').text())
  dashboard = new Dashboard($('#dashboard'))
  dashboard.createWidget(instance) for instance in instances
