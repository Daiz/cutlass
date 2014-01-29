should = require \chai .should!
require! '../read'
ass = require '../src/parser.ls'

suite \Script !->

  us-file = read './test/files/lines-unsorted.ass'
  us-script = new ass.Script us-file
  s-file = read './test/files/lines-sorted.ass'
  s-script = new ass.Script s-file

  test 'should sort by start time and layer number' !->
    us-script.sort!.to-ass!.should.equal s-file