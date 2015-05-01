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
    beforeEach -> storage._reset()

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
          bar = new model.models.base
          bar.url = -> '/tests/foo2'
          bar.fetch cb

        (_model, _options, cb) ->
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

    it 'should support model virtualization', (done) ->
      foo = new model.models.base
        foo: 'bar'
        bar: 'baz'
      foo.url = -> '/tests/foo9'

      # Create the virtual object
      virt1 = foo.cloneVirtual()
      virt1.get('foo').should.eql 'bar'
      virt1.set 'foo', 'baz'
      virt1.get('foo').should.eql 'baz'

      # Change property on original
      foo.get('foo').should.eql 'bar'
      foo.set 'bar', 'foo'

      # And make sure it is reflected
      virt1.get('bar').should.eql 'foo'

      # Make it a real object
      virt1.makeReal()

      foo.set 'bar', 'bar'
      virt1.get('bar').should.eql 'foo'
      done null

    it 'should update on second save', (done) ->
      foo = new model.models.base
        foo: 'bar'
      foo.url = '/tests/foo10'

      foo2 = new model.models.base
      foo2.url = '/tests/foo10'

      async.waterfall [
        (cb) ->
          foo.save cb
        (_model, _options, cb) ->
          storage._history.getLast().should.have.properties
            method: 'create'
            url: '/tests/foo10'

          foo.set 'foo', 'baz'
          foo.save cb

        (_model, _options, cb) ->
          storage._history.getLast().should.have.properties
            method: 'update'
            url: '/tests/foo10'

          foo2.fetch cb

        (_model, _options, cb) ->
          foo2.get('foo').should.eql 'baz'
          foo2.set 'foo', 'bar'
          foo2.save cb

        (_model, _options, cb) ->
          storage._history.getLast().should.have.properties
            method: 'update'
            url: '/tests/foo10'
          cb null
      ], done

  describe 'Collection', ->
    Root = null
    root = null
    Thing = null
    ThingCollection = null
    Widget = null
    WidgetCollection = null

    before (done) ->
      Widget = class Widget extends model.models.base

      WidgetCollection = class WidgetCollection extends model.collections.base
        model: Widget
        urlPart: 'widgets'

      Thing = class Thing extends model.models.base
        storedCollections: ['widgets']
        initialize: ->
          @widgets = new WidgetCollection @

      ThingCollection = class ThingCollection extends model.collections.base
        model: Thing
        urlPart: 'things'

      Root = class Root extends model.models.base
        url: '/root'
        storedCollections: ['things']
        initialize: ->
          @things = new ThingCollection @

      done null

    beforeEach -> storage._reset()

    it 'should save/load its children', (done) ->
      root = new Root
        one: 'one'
      thing1 = new Thing
        id: 'thing1'
        two: 'two'
      thing2 = new Thing
        id: 'thing2'
        three: 'three'
      widget1 = new Widget
        id: 'widget1'
        four: 'four'

      root.things.add thing1
      root.things.add thing2
      thing2.widgets.add widget1

      root.isNew().should.be.true
      thing1.isNew().should.be.true
      thing2.isNew().should.be.true
      widget1.isNew().should.be.true

      root2 = null

      async.waterfall [
        (cb) ->
          root.save recursive: true, cb
        (model, options, cb) ->
          root.isNew().should.be.false
          thing1.isNew().should.be.false
          thing2.isNew().should.be.false
          widget1.isNew().should.be.false
          root2 = new Root
          root2.fetch recursive: true, cb
        (model, options, cb) ->
          model.should.eql.root2
          root2.get('one').should.eql 'one'
          root2.things.length.should.eql 2
          root2.things.get('thing1').get('two').should.eql 'two'
          root2.things.get('thing2').get('three').should.eql 'three'
          root2.things.get('thing2').widgets.get('widget1').get('four')
            .should.eql 'four'
          cb null
      ], done

    it 'should update on second save', (done) ->
      root = new Root
        one: 'one'
      thing1 = new Thing
        id: 'thing1'
        two: 'two'
      thing2 = new Thing
        id: 'thing2'
        three: 'three'
      widget1 = new Widget
        id: 'widget1'
        four: 'four'

      root.things.add thing1
      root.things.add thing2
      thing2.widgets.add widget1

      root2 = new Root

      async.waterfall [
        (cb) ->
          root.save recursive: true, cb

        (model, options, cb) ->
          root.save cb

        (model, options, cb) ->
          storage._history.getLast().should.have.properties
            url: '/root'
            method: 'update'

          thing1.save cb

        (model, options, cb) ->
          storage._history.getLast().should.have.properties
            url: '/root/things/thing1'
            method: 'update'

          root2.fetch recursive:true, cb

        (model, options, cb) ->
          root2.things.get('thing1').set 'two', 'foo'
          root2.things.get('thing1').save cb

        (model, options, cb) ->
          storage._history.getLast().should.have.properties
            url: '/root/things/thing1'
            method: 'update'

          cb null

      ], done

    it 'parent should not be destroyable if it has children'
    it 'should allow destroying all children'
