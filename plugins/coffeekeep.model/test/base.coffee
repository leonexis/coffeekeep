path = require 'path'
async = require 'async'
should = require 'should'
coffeekeep = require 'coffeekeep'

config = [
  './coffeekeep.log'
  './coffeekeep.model'
  './coffeekeep.storage.memory'
]

describe 'coffeekeep.model:base', ->
  app = null
  model = null
  log = null
  storage = null
  before (done) ->
    coffeekeep.createApp config, (err, _app) ->
      return done err if err?
      app = _app
      model = app.getService 'model'
      storage = app.getService 'storage'
      done null

  after ->
    app.destroy()

  describe 'Model', ->
    it 'should allow setting and retreiving attributes', ->
      foo = new model.models.base
      foo.set 'bar', 'baz'
      foo.get('bar').should.eql 'baz'
      (should foo.get 'notreal').eql undefined
      (should foo.get 'notreal', 'foo').eql 'foo'

    it 'should allow specifying attributes on creation', ->
      foo = new model.models.base foo: 'bar'
      foo.get('foo').should.eql 'bar'

    it 'should allow saving a new entry to a data store', (done) ->
      foo = new model.models.base
      foo.url = -> "/tests/foo"

      async.waterfall [
        (cb) ->
          # new save format:
          # model.save [options,] callback
          foo.save cb

        (_model, _options, cb) ->
          _model.should.eql foo
          storage._db.should.have.property '/tests/foo'
          cb null
      ], done

    it 'should be able to retreive from a data store', (done) ->
      foo = new model.models.base
        foo: 'bar'
      foo.url = -> '/tests/foo2'
      bar = null

      async.waterfall [
        (cb) ->
          foo.save cb

        (_model, _options, cb) ->
          console.log "saved, fetching", _model, _options, cb
          bar = new model.models.base
          bar.url = -> '/tests/foo2'
          bar.fetch cb

        (_model, _options, cb) ->
          console.log "fetched"
          bar.get('foo').should.eql 'bar'
          _model.should.eql bar
          cb null
      ], done

    it 'should be able to update a data store', (done) ->
      foo = new model.models.base
        foo: 'bar'
      foo.url = -> '/tests/foo3'

      async.waterfall [
        (cb) ->
          foo.save cb

        (_model, _options, cb) ->
          data = JSON.parse storage._db['/tests/foo3']
          data.should.have.property 'foo', 'bar'
          foo.set 'foo', 'baz'
          foo.save cb

        (_model, _options, cb) ->
          data = JSON.parse storage._db['/tests/foo3']
          data.should.have.property 'foo', 'baz'
          cb null
      ], done

    it 'should be deleteable', (done) ->
      foo = new model.models.base
      foo.url = -> '/tests/foo4'

      async.waterfall [
        (cb) ->
          foo.save cb
        (_model, _options, cb) ->

          storage._db.should.have.property '/tests/foo4'
          foo.destroy cb

        (_model, _options, cb) ->
          storage._db.should.not.have.property '/tests/foo4'
          cb null
      ], done

    it 'should trigger events on creation', (done) ->
      foo = new model.models.base
      foo.url = -> '/tests/foo5'
      foo.once 'save', (model, opts) ->
        model.should.eql foo
        done null

      foo.save()

    it 'should trigger events on updates from data store', (done) ->
      foo = new model.models.base
        foo: 'bar'
      foo.url = -> '/tests/foo6'
      bar = new model.models.base
      bar.url = -> '/tests/foo6'

      async.waterfall [
        (cb) ->
          foo.save cb

        (_foo_model, _options, cb) ->
          # Test 'change' event
          bar.once 'change', (args...) ->
            cb null, args...
          bar.fetch (err) -> cb err if err?

        (_bar_model, _options, cb) ->
          _bar_model.should.eql bar
          foo.set 'foo', 'baz'
          foo.save cb

        (_foo_model, _options, cb) ->
          _foo_model.should.eql foo
          # Test 'change:%' event
          bar.once 'change:foo', (args...) ->
            cb null, args...
          bar.fetch (err) -> cb err if err?

        (_bar_model, value, _options, cb) ->
          _bar_model.should.eql bar
          value.should.eql 'baz'
          cb null
      ], done

    it 'should trigger events on updates from setting attributes', (done) ->
      foo = new model.models.base
        foo: 'bar'
      foo.url = -> '/tests/foo7'

      async.waterfall [
        (cb) ->
          foo.once 'change', (args...) -> cb null, args...
          foo.set 'foo', 'baz'
        (_model, _options, cb) ->
          foo.once 'change:foo', (args...) -> cb null, args...
          foo.set 'foo', 'bar'
      ], done

    it 'should trigger events on deletion', (done) ->
      foo = new model.models.base
      foo.url = -> '/tests/foo8'

      async.waterfall [
        (cb) ->
          foo.save cb
        (_model, _options, cb) ->
          foo.once 'destroy', (args...) -> cb null, args...
          foo.destroy (err) -> cb err if err?
        (_model, _collection, _options, cb) ->
          _model.should.eql foo
          cb null
      ], done

    it 'should support model virtualization'
  describe 'Collection', ->
    it 'should save its children'
    it 'should automatically save when the parent is saved recursively'
    it 'parent callback should only be called after collections save'
