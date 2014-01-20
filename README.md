# cutlass - JS library for ASS subtitles

*cutlass* is a Node.js module / JavaScript library for parsing and dealing with ASS subtitles.

## Installation

Installation is simple with npm:

```bash
$ npm install cutlass
```

## Basic Info and Examples

*cutlass* exports an object with four classes: Script, Event, Style and Color. The one you usually want to deal with is Script, which represents a whole ASS script.

```javascript
var ass = require('cutlass');
var rawAss1 = "..." // pretend this is a full ASS script read from disk
var rawAss2 = "..." // this too

var script1 = new ass.Script(rawAss1);

// sort the script by event start time
script1.sort();

// get the script as raw ASS
var rawScript1 = script1.toAss();

var script2 = new ass.Script(rawAss2);

// for this script, we want to move all lines with the style "Sign" to the top.
// `script.events` is a plain JS array, so we can use them our purpose here.
var signs = [];
var dialogue = [];
for (var i = 0, len = script2.events.length; i < len; ++i) {
  var line = script2.events[i];
  if (line.style === "Sign") {
    signs.push(line);
  } else {
    dialogue.push(line);
  }
}
script2.events = signs.concat(dialogue);

// get the script as ASS
var rawScript2 = script2.toAss();
```