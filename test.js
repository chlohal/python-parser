var fs = require("fs");
var path = require("path");

var pythonParser = require("./parser.js");

var testFile = fs.readFileSync(path.join(__dirname, "test.py")).toString();

var output = JSON.stringify(pythonParser.parse(testFile), null, 2);

var testOutput = fs.readFileSync(path.join(__dirname, "test-output.json")).toString();

if(output !== testOutput) throw "Wrong output";