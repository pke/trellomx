http = require('http')
pubnub = require('pubnub')(
  ssl: true
  publish_key: 'pub-c-0b20bfbc-2c49-4f20-82ac-659d8ebb490c'
  subscribe_key: 'sub-c-f3c0a50c-d79f-11e4-9532-0619f8945a4f')

port = process.env.port or 1337
console.info("Trello2PubNub Proxy running on #{port}")

http.createServer((req, res) ->
  if req.method is 'POST'
    jsonString = ''

    req.on 'data', (data) ->
      jsonString += data

    req.on 'end', (data) ->
      message = JSON.parse(jsonString)
      pubnub.publish
        channel: req.url.substr(1)
        message: message
        callback: ->
          console.log("POSTED #{message.action.type}: #{JSON.stringify(message, null, 2)}")
        error: (e) ->
          console.error("FAILED to publish #{message.action.type}", e)
      res.writeHead(200, 'OK', 'Content-Type': 'text/plain')
      res.end()
  else if req.method == 'HEAD'
    console.log("HEAD #{req.url}")
    res.writeHead(200, 'Content-Type': 'text/plain')
    res.end()
).listen port