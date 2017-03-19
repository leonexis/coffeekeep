backbone = require 'backbone'
util = require 'util'
async = require 'async'
_ = require 'lodash'
debug = require 'debug'

UNSPECIFIED = new Object

exports.Model = class Model extends backbone.Model
  _debug: debug 'coffeekeep.model:base.Model'
  debug: (args...) ->
    @_debug args...
    @log.silly args...

  storedCollections: []
  constructor: (args...) ->
    super args...
    @log = new @Logger => @toString()
    @lastSync = null
    @virtual = null

    @on 'add', (model, collection, options) =>
      return unless @ is model
      @debug "@on 'add' (%j, %j, %j)", model, collection, options

      # If the model was added to a collection via a fetch, make sure to
      # set lastSync
      # FIXME: This seems like a poor way to do it
      if options.merge
        @debug "@on 'add': option.merge, setting @lastSync"
        @lastSync = do Date.now

    @on 'sync', (model, collection, options) =>
      return unless @ is model
      @debug "@on 'sync' (%j, %j, %j)", model, collection, options
      @lastSync = do Date.now

    #@on 'all', (id, model, collections, options) =>
    #  return unless @ is model
    #  return if id.indexOf('change') is 0
    #  console.log "#{do @toString} got event #{id} with options
    #    {util.inspect options}"

  toString: -> "[#{@constructor.name} #{@id}]"
  isNew: -> not @lastSync?

  url: ->
    # TODO make sure that id is urlescaped!
    if not @collection?
      @log.error "Tried to get url for #{util.inspect @}, but no collection"
      return null
    containerUrl = _.result @collection, 'url'
    containerUrl + @id

  loadCollections: (opts={}, callback) ->
    if @storedCollections.length is 0
      return process.nextTick callback

    @log.info "Loading my children"

    async.each @storedCollections,
      (collection, cb) =>
        @[collection].fetch opts, (err, model, opts) =>
          if err?
            @log.err "Error while fetching collections:", err, err.stack
            return cb err

          @log.notice "Loaded %d %s", @[collection].length, collection
          @emit 'loadedCollection', @[collection], @
          cb null

      (err) =>
        @emit 'loadedCollections', @ unless err?
        callback? err

  saveCollections: (opts={}, callback) ->
    # TODO: account for removed children
    if @storedCollections.length is 0
      return process.nextTick callback

    @log.info "Saving collections"

    async.eachSeries @storedCollections,
      (collection, cb) =>
        success = 0
        async.each @[collection].toArray(),
          (model, cb2) =>
            model.save opts, (err) =>
              return cb2 err if err?
              @log.silly "Saved %j", model
              success += 1
              cb2 null

          (err) =>
            if err?
              @log.error "Error while saving %s: %s", collection, err, err.stack
              return cb err

            @log.notice "Saved %d of %d %s", success,
              @[collection].length, collection
            cb err

      (err) =>
        if err?
          @log.error "Error while saving collections: %s", err, err.stack
          return callback? err

        @log.debug "Finished saving collections"
        callback? err

  # Recursive cloning
  cloneVirtual: (newId) ->
    # Create a new ID if needed by using the original id and appending it
    # with 4 random letters and numbers
    newId ?= @id + '_' + Math.floor(Math.random() * 1679616).toString(36)

    # Create a new empty model, but without triggering change events
    # normally caused by internally setting defaults
    model = new @constructor {}, silent: true

    # Clear the model attributes so model.get will get virtual values
    # by default
    model.defaults = {}
    model.attributes =
      id: newId
      virtualId: _.result @, 'url'
    model.set model.attributes

    # If we were already virtual, pass our virtual on, otherwise
    # Set ourself as the virtual to the new model
    model.virtual = @virtual ? @

    # Trigger reset from virtual
    model.resetFromVirtual()

    model

  resetFromVirtual: ->
    return if not @virtual? and not @getVirtual()?
    collections = @clonedCollections ? @storedCollections
    @defaults = {}
    @attributes =
      id: @attributes.id
      virtualId: @attributes.virtualId


    for collection in collections
      @[collection].reset()
      @virtual[collection].each (model, index, models) =>
        @[collection].add model.cloneVirtual()

  # Make an instance of a virtual model real by cloning current attributes
  # of the virtual model in to this model so that further changes to
  # the virtual model (or removal) will not affect this object. Used
  # especially when a player receives an item in to their inventory
  makeReal: ->
    return if not @virtual?
    @attributes = _.defaults @attributes, @virtual.attributes

  # Look up our own info. If we are virtual, continue search to there
  get: (attr, dflt) ->
    value = @attributes[attr]
    if not value? and @virtual?
      value = @virtual.attributes[attr]
    if not value?
      value = dflt
    value

  emit: (args...) -> @trigger args...

  save: (args...) ->
    # Prefer new style of .save [options], cb
    opts = {}
    cb = -> null
    if args.length is 2 and _.isFunction args[1]
      [opts, cb] = args
    else if args.length is 1 and _.isFunction args[0]
      [cb] = args
    else if args.length isnt 0
      err = new Error "Deprecated use of save"
      @log.notice "Deprecated use of save", err, err.stack
      return super args...

    callopts =
      success: =>
        cb null, @, opts
        @emit 'save', @, opts
      error: (model, response, options) => cb response, @, opts

    if opts.recursive
      _success = callopts.success
      callopts.success = =>
        @saveCollections opts, (err) =>
          return callopts.error @, err, opts if err?
          do _success

    super null, _.extend callopts, opts

  fetch: (args...) ->
    # Prefer new style of .fetch [options], cb
    opts = {}
    cb = -> null
    if args.length is 2 and _.isFunction args[1]
      [opts, cb] = args
    else if args.length is 1 and _.isFunction args[0]
      [cb] = args
    else if args.length isnt 0
      err = new Error "Deprecated use of fetch"
      @log.notice "Deprecated use of fetch", err, err.stack
      return super args...

    callopts =
      success: =>
        cb null, @, opts
        @emit 'fetch', @, opts
      error: (model, response, options) => cb response, @, opts

    if opts.recursive
      _success = callopts.success
      callopts.success = =>
        @loadCollections opts, (err) =>
          return callopts.error @, err, opts if err?
          do _success

    super _.extend callopts, opts

  destroy: (args...) ->
    # Prefer new style of .destroy [options], cb
    opts = {}
    cb = -> null
    if args.length is 2 and _.isFunction args[1]
      [opts, cb] = args
    else if args.length is 1 and _.isFunction args[0]
      [cb] = args
    else if args.length isnt 0
      err = new Error "Deprecated use of destroy"
      @log.notice "Deprecated use of destroy", err, err.stack
      return super args...

    callopts =
      success: =>
        @emit 'destroy', @, opts
        cb null, @, opts
      error: (model, response, options) => cb response @, opts

    super _.extend callopts, opts

exports.Collection = class Collection extends backbone.Collection
  _debug: debug 'coffeekeep.model:base.Model'
  debug: (args...) ->
    @_debug args...
    @log.silly args...

  constructor: (@parent, args...) ->
    super args...
    @log = new @Logger => @toString()

    @on 'add', (model, collection, options) =>
      return unless collection is @
      @debug "@on 'add' (%j, %j)", @parent, args
      model.world = collection.parent?.world

    @on 'remove', (model, collection, options) =>
      return unless collection is @
      @debug "@on 'remove' (%j, %j, %j)", model, collection, options
      model.world = null

    @on 'sync', (collection, response, options) =>
      # Make sure lastSync is updated
      return unless collection is @
      @debug "@on 'sync' (%j, %j, %j)", collection, response, options


    @parent.on 'destroy', (model, collection, options) =>
      return unless model is @parent
      @debug "@parent.on 'destroy' (%j, %j, %j)", model, collection, options
      # TODO: remove all our children

  toString: -> "[#{@constructor.name} in #{@parent?.toString()}]"
  url: ->
    if not @parent?
      @log.error "Tried to get container url for %j, but no @parrent.", @
      return null

    parentUrl = _.result @parent, 'url'
    if not parentUrl? or not @urlPart?
      @log.error "Tried to get container url for %j, but missing parentUrl (%s)
        or @urlPart (%s)", parentUrl, @urlPart
      return null

    parentUrl + '/' + @urlPart + '/'

  destroy: ->
    @parent = null

  emit: (args...) -> @trigger args...

  fetch: (args...) ->
    # Prefer new style of .fetch [options], cb
    opts = {}
    cb = -> null
    if args.length is 2 and _.isFunction args[1]
      [opts, cb] = args
    else if args.length is 1 and _.isFunction args[0]
      [cb] = args
    else if args.length isnt 0
      err = new Error "Deprecated use of fetch"
      @log.notice "Deprecated use of fetch", err, err.stack
      return super args...

    callopts =
      success: =>
        cb null, @, opts
        @emit 'fetch', @, opts
      error: (collection, response, options) => cb response, @, opts

    if opts.recursive
      _success = callopts.success
      callopts.success = =>
        async.forEach @models,
          (model, cb) ->
            model.loadCollections opts, cb
          (err) =>
            return callopts.error @, err, opts if err?
            do _success

    super _.extend callopts, opts

  create: (attributes, options={}, cb) ->
    cb ?= -> null
    model = attributes
    if model not instanceof @model
      model = new @model attributes

    @add model
    model.save options, cb
