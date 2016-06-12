Request = require 'request'
FeedParser = require 'feedparser'

module.exports = (server) =>
  log = server.log
  articles = []
  
  addArticle = (article) ->
    for existingArticle in articles
      return if existingArticle.permalink is article.permalink
    articles.push article
    articles.shift() while articles.length > 6
  
  updateFeeds = ->
    for feed in server.config.feeds
      request = Request feed,
        encoding: null
      parser = FeedParser()
      
      server.log.debug 'Loafing articles from feed "%s"', feed
      request.on 'error', (error) ->
        server.log.error 'Failed to update articles on "%s": %s', feed, error
      request.on 'response', (response) ->
        return server.log.error 'Error %s for feed "%s"', response.statusCode, feed if response.statusCode isnt 200
        @pipe parser
      parser.on 'error', (error) ->
        server.log.error 'Failed to parse articles on "%s": %s', feed, error
      parser.on 'readable', ->
        while item = @read()
          addArticle item
    
  server.init = (next) ->
    updateFeeds()
    #setTimeout updateFeeds, 30000
    next()
    
  server.handle 'articles', (query, respond, error) ->
    respond articles