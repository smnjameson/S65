const WebSocket = require('ws');
const fs = require('fs')

var ws = new WebSocket("ws://localhost:8082");
ws.binaryType = 'arraybuffer';

ws.onopen = () => {
    let data = fs.readFileSync(process.argv[2])

    ws.send(data);

    ws.onmessage = function(message) {
        ws.close()
    };    

    ws.onclose = () => {
        process.exit(1)
    }
}

