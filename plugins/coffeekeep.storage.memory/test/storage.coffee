path = require 'path'
async = require 'async'
config = require './config'
coffeekeep = require 'coffeekeep'

describe 'coffeekeep.storage.memory', ->
  app = null
  storage = null
  model = null
  before (done) ->
    coffeekeep.createApp config, (err, _app) ->
      return done err if err?
      app = _app
      storage = app.getService 'storage'
      model = app.getService 'model'
      done null

  after ->
    app.destroy()

  describe 'model integration', ->
    world = null

    before ->
      world = app.getService 'world'

    it 'should support saving', (done) ->
      world.save null,
        success: (model, response, options) ->
          done null
        error: (model, response, options) ->
          done response

  describe 'sync', ->
    sync = null
    db = null

    class FakeModel
      constructor: (@attributes) ->
      get: (key) -> @attributes[key]
      set: (key, value) -> @attributes[key] = value
      url: -> @attributes['url']
      trigger: ->

    class FakeCollection extends FakeModel
      constructor: (@parent, args...) ->
        super args...
      url: -> @parent.url() + '/' + @attributes['url'] + '/'

    before ->
      sync = storage.sync
      db = storage._db

    it 'should support create', (done) ->
      data = new FakeModel
        url: "/foo"
        foo: "bar"

      sync 'create', data,
        error: (err) ->
          done err
        success: ->
          db.should.have.property '/foo'
          JSON.parse db['/foo']
            .should.have.property 'foo', 'bar'
          done null

    it 'should support read', (done) ->
      db['/bar'] = JSON.stringify
        url: '/bar'
        foo: 'baz'

      data = new FakeModel
        url: '/bar'

      sync 'read', data,
        error: (err) ->
          done err
        success: (newdata) ->
          newdata.should.have.property 'foo', 'baz'
          done null

    it 'should error if resource not found', (done) ->
      data = new FakeModel
        url: '/nothere'

      sync 'read', data,
        error: (err) ->
          err.should.be.instanceof storage.NotFoundError
          done null
        success: ->
          done new Error 'No error thrown'

    it 'should support read on collections', (done) ->
      db['/root/foo/bar'] = JSON.stringify
        one: 'one'
      db['/root/foo/baz'] = JSON.stringify
        two: 'two'
      db['/root/foo'] = JSON.stringify
        three: 'three'

      root = new FakeModel
        url: '/root'

      data = new FakeCollection root,
        url: 'foo'

      sync 'read', data,
        error: (err) ->
          done err
        success: (newdata) ->
          newdata.should.have.length 2
          newdata.should.containDeep [{one:'one'}]
          newdata.should.containDeep [{two:'two'}]
          newdata.should.not.containDeep [{three:'three'}]
          done null

    it 'should support update', (done) ->
      db['/bar'] = JSON.stringify
        url: '/bar'
        foo: '/bar'

      data = new FakeModel
        url: '/bar'

      data.set 'foo', 'baz'
      sync 'update', data,
        error: (err) -> done err
        success: ->
          JSON.parse db['/bar']
            .should.have.property 'foo', 'baz'
          done null

    it 'should support delete', (done) ->
      db['/bar'] = JSON.stringify
        url: '/bar'
        foo: '/bar'

      data = new FakeModel
        url: '/bar'

      sync 'delete', data,
        error: (err) -> done err
        success: ->
          db.should.not.have.property '/bar'
          done null

    it 'should not save an update to a non-existant record', (done) ->
      data = new FakeModel
        url: '/bar'
        foo: 'bar'

      sync 'update', data,
        error: (err) ->
          err.should.be.instanceof storage.NotFoundError
          done null
        success: ->
          done new Error 'Did not give an error!'

    it 'should not create a record when its url already exists', (done) ->
      data = new FakeModel
        url: '/bar'
        foo: 'bar'

      db['/bar'] = JSON.stringify
        url: '/bar'
        foo: 'baz'

      sync 'create', data,
        error: (err) ->
          err.should.be.instanceof storage.ExistsError
          done null
        success: ->
          done new Error 'Did not give an error!'

    it 'should not return sub-children during a collection read', (done) ->
      db['/root/foo/bar'] = JSON.stringify
        one: 'one'
      db['/root/foo/baz'] = JSON.stringify
        two: 'two'
      db['/root/foo/baz/foo'] = JSON.stringify
        three: 'three'

      root = new FakeModel
        url: '/root'

      data = new FakeCollection root,
        url: 'foo'

      sync 'read', data,
        error: (err) ->
          done err
        success: (newdata) ->
          newdata.should.have.length 2
          newdata.should.containDeep [{one:'one'}]
          newdata.should.containDeep [{two:'two'}]
          newdata.should.not.containDeep [{three:'three'}]
          done null
