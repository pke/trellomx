http = require('http')

createProxyServer = (pubnub, logger = console) ->
  http.createServer (req, res) ->
    if req.method is 'POST'
      jsonString = ''

      req.on 'data', (data) ->
        jsonString += data

      req.on 'end', ->
        message = JSON.parse(jsonString)
        pubnub.publish(
          channel: req.url.substr(1)
          message: message
        ).then(->
          logger.log("POSTED #{message.action.type}: #{JSON.stringify(message, null, 2)}")
        ).catch (e) ->
          logger.error("FAILED to publish #{message.action.type}", e)

        res.writeHead(200, 'OK', 'Content-Type': 'text/plain')
        res.end()
    else if req.method == 'HEAD'
      logger.log("HEAD #{req.url}")
      res.writeHead(200, 'Content-Type': 'text/plain')
      res.end()

module.exports = { createProxyServer }

if require.main is module
  PubNub = require('pubnub')
  pubnub = new PubNub(
    ssl: true
    publishKey: 'pub-c-0b20bfbc-2c49-4f20-82ac-659d8ebb490c'
    subscribeKey: 'sub-c-f3c0a50c-d79f-11e4-9532-0619f8945a4f'
    userId: 'trellomx-webhook-proxy')

  port = process.env.port or 1337
  server = createProxyServer(pubnub)
  server.listen port, ->
    console.info("Trello2PubNub Proxy running on #{port}")
