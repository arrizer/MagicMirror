Request = require 'request'
FeedParser = require 'feedparser'

module.exports = (server) =>
  log = server.log
  articles = []
  
  addArticle = (article) ->
    for existingArticle in articles
      return if existingArticle.permalink is article.permalink
    articles.push (title: article.title, pubdate: article.pubdate, permalink: article.permalink)
    articles.sort (a,b) ->
      return -1 if a.pubdate > b.pubdate
      return 1 if a.pubdate < b.pubdate
      return 0
    articles.shift() while articles.length > 10
  
  updateFeeds = ->
    for feed in server.config.feeds
      request = Request feed,
        encoding: null
      parser = FeedParser()
      
      server.log.debug 'Loading articles from feed "%s"', feed
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
    setInterval (=> updateFeeds()), (1000 * 60 * 5)
    next()
    
  server.handle 'articles', (query, respond, error) ->
    respond articles