# Python Parser

This is a naive Python parser in pure Javascript: no WASM, shell calls, or any non-JS. It has *no* runtime dependencies.

If you want to parse Python in the browser, then this is your project! I made this with PegJS when I couldn't find any pure-JS Python parsers. It's designed to be as easily usable as possible.


## How to Use

### Using in the Browser

1) Add the [parser.js](./parser.js) file to your page
2) Call the `pythonParser.parse(/*...code...*/)` method.

### Using in NodeJS

1) `require("parser.js")`
2) Call the `pythonParser.parse(/*...code...*/)` method.

## Parser Output

I hope that the output object can be understood with a glance at the [test output](./test-output.json). You can also take a look at the [Python grammar](./python.pegjs) to see the exact format.

## PegJS

This project uses [PegJS](https://github.com/pegjs/pegjs) for parsing, which is [available under the MIT License](https://github.com/pegjs/pegjs/blob/master/LICENSE). The PegJS-generated parser is 1 Javascript file that doesn't depend on anything!

## Questions

**How is this different from [Skulpt](https://skulpt.org/)?**  
Skulpt runs Python. This project *only* parses it and then gives you a syntax tree. You can use that for whatever you like: code formatting; static code analysis; even making your own interpreter!

**I'm getting syntax errors!**

Try adding newlines to the end of your input: e.g. instead of `pythonParser.parse(input)`, try `pythonParser.parse(input + "\n\n")`. If you're experiencing a larger error, please open an issue.
