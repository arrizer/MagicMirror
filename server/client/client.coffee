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
        string: (key) -> strings[key]
        config: instance.config
        globalConfig: JSON.parse(decode $('#config').text())
        load: (endpoint, data, next) ->
          unless next?
            next = data
            data = null
          $.ajax
            type: 'GET'
            url: instance.instanceID + '/' + endpoint
            success: (message, status) =>
              if message.success
                next null, message.response
              else
                next new Error(message.error) if next?
            error: (xhr, status, error) =>
              message = 'Unknown error'
              if xhr.status is 0
                message = 'Could not connect to the server'
              else if xhr.status > 0
                response = null
                response = JSON.parse(xhr.responseText) if xhr.responseText?
                message = (if response? then response.error else 'Server error')
              else if error is 'parsererror'
                message = 'Failed to parse server response'
              else if error is 'timeout'
                message = 'Request timed out'
              next message if next?
            dataType: 'json'
            data: data
      widgetFactories[instance.widget](widget)
      widget.init (=>)
      @widgets.push widget
  
  instances = JSON.parse(decode $('#widget_instances').text())
  dashboard = new Dashboard($('#dashboard'))
  dashboard.createWidget(instance) for instance in instances
