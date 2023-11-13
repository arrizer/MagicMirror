XMLRPC = require 'xmlrpc'
OS = require 'os'

SERVER_PORT = 9999

module.exports = (server) =>
  log = server.log
  xmlrpcClient = XMLRPC.createClient(host: server.config.ccuHost, port: 2001, path: '/')

  getValues = (values) ->
    new Promise (resolve, reject) ->
      calls = values.map (value) ->
        address = value.split('.')[0]
        key = value.split('.')[1]
        return (methodName: 'getValue', params: [address, key])
      xmlrpcClient.methodCall 'system.multicall', [calls], (error, response) ->
        return reject(error) if error?
        return reject(new Error("Unexpected response: #{response}")) unless Array.isArray(response) and response.length == values.length
        result = {}
        index = 0
        for value in values
          result[value] = response[index][0]
          index++
        console.log(result)
        return resolve(result)

  server.handle 'openWindows', (query) ->
    values = []
    for name,value of server.config.openWindows
      if Array.isArray(value)
        values = values.concat(value)
      else
        values.push(value)
    results = await getValues(values)
    data = {}
    for name,value of server.config.openWindows
      if Array.isArray(value)
        data[name] = false
        for subvalue in value
          data[name] = true if results[subvalue]
      else
        data[name] = results[value]
    return data
