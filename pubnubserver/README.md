# pubnubserver

Trello wants to send a `HEAD` request to the `callbackURL` when installing a webhook. PubNub does not support this and responds with 404. The Trello in turn ignores the webhook.

This little nodejs server works as a proxy, responds to `HEAD` requests and publishes the webhooks `POST ` payload to PubNub.

The server must be running for notifications to work. The app is currently using a hardcoded `callbackURL` host that points to my dynip:
`http://pfcpille.no-ip.biz:1337`

If you want to test notifications you need to change this URL to your computers exposed dynip (and forward the port in the router).

