var glob = require('glob');
var fs = require('fs');

var addBom = function(content) {
    if (content.charCodeAt(0) === 65279) {
        return new Buffer(content);
    } else {
        contentBuffer = new Buffer(content);
        outBuffer = new Buffer(contentBuffer.length + 3);
        outBuffer.writeUInt8(0xEF, 0);
        outBuffer.writeUInt8(0xBB, 1);
        outBuffer.writeUInt8(0xBF, 2);
        contentBuffer.copy(outBuffer, 3);
        return outBuffer;
    }
}

var files = glob.sync('../trello.*/**/*/*.js');

var addBomToFile = function (file) {
    var content = fs.readFileSync(file);
    buffer = addBom(content.toString());
    if (buffer[0] != content[0]) {
        console.log('Adding BOM to ' + file);
    }
    fs.writeFileSync(file, buffer);
}
files.forEach(addBomToFile);
//process.exit(0);
