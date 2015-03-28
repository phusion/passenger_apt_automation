var http = require('http');
var server = http.createServer(function(req, res) {
	res.writeHead(200, { 'Content-Type': 'text/plain' });
	res.end("Hello Node.js\n");
});
server.listen('127.0.0.1', 3000);
