module.exports = (server) =>
  log = server.log

  server.init = (next) ->
    log.info "Hello there, news widget-server is initializing :-)"
    next()
    
  server.handle 'greet', (query, respond, error) ->
    respond "Tach " + query.name