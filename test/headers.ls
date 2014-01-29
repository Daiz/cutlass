should = require \chai .should!
require! '../read'
ass = require '../src/parser.ls'

suite \Headers !->

  test 'should be identical after load-export' !->
    file = read './test/files/headers.ass'
    script = new ass.Script file .to-ass!
    script.should.equal file

