backbone = require 'backbone'
util = require 'util'
async = require 'async'
_ = require 'underscore'
debug = require 'debug'

exports.Model = class Model extends backbone.Model
  _debug: debug 'coffeekeep.model:base.Model'
  debug: (args...) ->
    @_debug args...
    @log.silly args...

  storedCollections: []
  constructor: (args...) ->
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

      # If we were loaded from the db, then load our collections
      do @loadCollections unless do @isNew

    @on 'sync', (model, collection, options) =>
      return unless @ is model
      @debug "@on 'sync' (%j, %j, %j)", model, collection, options
      @lastSync = do Date.now
      do @saveCollections if options.recursive

    #@on 'all', (id, model, collections, options) =>
    #  return unless @ is model
    #  return if id.indexOf('change') is 0
    #  console.log "#{do @toString} got event #{id} with options
    #    {util.inspect options}"

    super args...

  toString: -> "[#{@constructor.name} #{@id}]"
  isNew: -> not @lastSync?

  url: ->
    # TODO make sure that id is urlescaped!
    if not @collection?
      @log.error "Tried to get url for #{util.inspect @}, but no collection"
      return null
    containerUrl = _.result @collection, 'url'
    containerUrl + @id

  loadCollections: (callback) ->
    return if @storedCollections.length is 0
    @log.info "Loading my children"

    async.each @storedCollections,
      (collection, cb) =>
        @[collection].fetch
          success: =>
            @log.notice "Loaded %d %s", @[collection].length, collection
            @emit 'loadedCollection', @[collection], @
            do cb
          error: (err) =>
            @log.error "Error while fetching collections:", err
            cb err
      (err) =>
        @emit 'loadedCollections', @ unless err?
        callback? err

  saveCollections: (callback) ->
    # TODO: account for removed children
    return if @storedCollections.length is 0

    @log.info "Saving collections"

    async.each @storedCollections,
      (collection, cb) =>
        success = 0
        async.each @[collection].toArray(),
          (model, cb2) =>
            model.save null,
              success: =>
                @log.silly "Saved %j", model
                success += 1
                do cb2
              error: (err) ->
                cb2 err
          (err) =>
            @log.notice "Saved %d of %d %s", success,
              @[collection].length, collection
            cb err
      (err) =>
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
  get: (attr) ->
    value = @attributes[attr]
    if not value? and @virtual?
      value = @virtual.attributes[attr]
    value

  emit: (args...) -> @trigger args...

exports.Collection = class Collection extends backbone.Collection
  _debug: debug 'coffeekeep.model:base.Model'
  debug: (args...) ->
    @_debug args...
    @log.silly args...

  constructor: (@parent, args...) ->
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

    super args...

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
