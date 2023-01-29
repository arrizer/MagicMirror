FormURLEncoded = require 'form-urlencoded'
HTTP = require 'http'
HTTPS = require 'https'

module.exports = class HTTPClient
  constructor: (@log) ->

  get: (url) =>
    await @request
      method: 'GET'
      url: url
  
  getJSON: (url) =>
    await @request
      method: 'GET'
      url: url
      responseContentType: 'json'

  post: (url, requestBody) =>
    await @request
      method: 'POST'
      url: url
      requestBody: requestBody
  
  postJSON: (url, requestBody) =>
    await @request
      method: 'POST'
      url: url
      responseContentType: 'json'
      requestBody: requestBody
  
  postForm: (url, form) =>
    await @request
      method: 'POST'
      url: url
      responseContentType: 'json'
      requestBody: form
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
      requestContentType: 'form'
  
  request: (options) ->
    throw new Error("URL missing") unless options.url?
    try
      client = (if new URL(options.url).protocol is 'https:' then HTTPS else HTTP)
      response = await new Promise (resolve, reject) =>
        reqOptions =
          method: options.method or 'GET'
          headers: options.headers
        req = client.request options.url, reqOptions, (res) =>
          if res.statusCode isnt 200
            req.abort()
            reject(new Error("HTTP status #{res.statusCode}"))
          data = ''
          res.on 'data', (chunk) => 
            data += chunk
          res.on 'end', =>
            if options.responseContentType is 'json'
              try
                data = JSON.parse(data)
              catch error
                reject(error)
            resolve(data)
        req.on 'error', (error) =>
          reject(error)
        requestBody = options.requestBody
        requestBody = JSON.stringify(requestBody) if options.requestContentType is 'json' and requestBody?
        requestBody = FormURLEncoded(requestBody) if options.requestContentType is 'form' and requestBody?
        req.write(requestBody) if requestBody?
        @log.debug "Performing HTTP request: #{reqOptions.method} #{options.url}"
        req.end()
      if options.responseContentType is 'json'
        @log.debug "Response: #{JSON.stringify(response, null, 2)}"
      return response
    catch error
      @log.error "Error loading #{options.method} #{options.url}: #{error}"
      throw error
