var http = require('http');
var pubnub = require("pubnub")({
    ssl           : true,  // <- enable TLS Tunneling over TCP
    publish_key: 'pub-c-0b20bfbc-2c49-4f20-82ac-659d8ebb490c',
    subscribe_key: 'sub-c-f3c0a50c-d79f-11e4-9532-0619f8945a4f'
});
var port = process.env.port || 1337;
http.createServer(function (req, res) {
    if (req.method === "POST") {
        var jsonString = '';
        req.on('data', function (data) {
            jsonString += data;
        });
        req.on('end', function (data) {
            pubnub.publish({
                channel   : req.url.substr(1),
                message   : JSON.parse(jsonString),
                callback  : function (e) { console.log("SUCCESS!", e); },
                error     : function (e) { console.log("FAILED! RETRY PUBLISH!", e); }
            });
            res.writeHead(200, "OK", { 'Content-Type': 'text/html' });
            res.end();
        });
    } else if (req.method === "HEAD") {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end();
    }
}).listen(port);