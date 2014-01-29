should = require \chai .should!
require! '../read'
ass = require '../src/parser.ls'

suite \Headers !->
  
  file = read './test/files/headers.ass'
  script = new ass.Script file

  test 'should be identical after load-export' !->
    script.to-ass!.should.equal file

  test 'should be readable' !->
    script.header \PlayResX .should.equal \1280

  test 'should be writable' !->
    script.header \Test \Write
    script.header \Test .should.equal \Write

  test 'should be group writable' !->
    script.header do
      foo: \bar
      baz: \qux

    script.header \foo .should.equal \bar
    script.header \baz .should.equal \qux
