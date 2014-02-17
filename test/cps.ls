should = require \chai .should!
require! '../read'
ass = require '../src/parser.ls'

# t - test
# c - control

suite \CPS !->

  t-file = read './test/files/cps.ass'
  t-script = new ass.Script t-file
  c-file = read './test/files/cps-calculated.ass'
  c-script = new ass.Script c-file

  test 'should be counted properly' !->
    for line, i in t-script.events
      c-cps = parse-int (c-script.events[i].effect.match /\d\d/)?0, 10
      t-cps = line.cps!
      t-cps.should.equal c-cps