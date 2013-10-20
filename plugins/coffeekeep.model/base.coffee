backbone = require 'backbone'
util = require 'util'
async = require 'async'
_ = require 'underscore'

exports.Model = class Model extends backbone.Model
    storedCollections: []
    constructor: (args...) ->
        @lastSync = null
        @virtual = null

        @on 'add', (model, collection, options) =>
            return unless @ is model

            # If the model was added to a collection via a fetch, make sure to
            # set lastSync
            # FIXME: This seems like a poor way to do it
            if options.merge
                @lastSync = do Date.now

            # If we were loaded from the db, then load our collections
            do @loadCollections unless do @isNew

        @on 'sync', (model, collection, options) =>
            return unless @ is model
            @lastSync = do Date.now
            do @saveCollections if options.recursive

        #@on 'all', (id, model, collections, options) =>
        #    return unless @ is model
        #    return if id.indexOf('change') is 0
        #    console.log "#{do @toString} got event #{id} with options #{util.inspect options}"

        super args...

    isNew: -> not @lastSync?

    url: ->
        # TODO make sure that id is urlescaped!
        if not @collection?
            console.error "Tried to get url for #{util.inspect @}, but no collection"
            return null
        containerUrl = _.result @collection, 'url'
        containerUrl + @id

    loadCollections: (callback) ->
        return if @storedCollections.length is 0
        console.log "Loading children for #{do @toString}"

        async.each @storedCollections,
            (collection, cb) =>
                @[collection].fetch
                    success: =>
                        console.log "#{@}: Loaded #{@[collection].length} #{collection}"
                        @emit 'loadedCollection', @[collection], @
                        do cb
                    error: (err) =>
                        console.error "Error while fetching collections: #{err.stack}"
                        cb err
            (err) =>
                @emit 'loadedCollections', @ unless err?
                callback? err

    saveCollections: (callback) ->
        # TODO: account for removed children
        return if @storedCollections.length is 0

        console.log "Saving children for #{do @toString}"

        async.each @storedCollections,
            (collection, cb) =>
                async.each @[collection].toArray(),
                    (model, cb2) ->
                        model.save
                            success: ->
                                do cb2
                            error: (err) ->
                                cb2 err
                    (err) -> cb err
            (err) -> callback? err

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
    constructor: (@parent, args...) ->
        @on 'add', (model, collection, options) =>
            return unless collection is @
            model.world = collection.parent?.world

        @on 'remove', (model, collection, options) =>
            return unless collection is @
            model.world = null

        @on 'sync', (collection, response, options) =>
            # Make sure lastSync is updated
            return unless collection is @


        @parent.on 'destroy', (model, collection, options) =>
            return unless model is @parent
            # TODO: remove all our children

        super args...

    url: ->
        if not @parent?
            console.error "Tried to get container url for #{util.inspect @}, but no @parrent."
            return null

        parentUrl = _.result @parent, 'url'
        if not parentUrl? or not @urlPart?
            console.error "Tried to get container url for #{util.inspect @}, but missing #{parentUrl} or #{@urlPart}"
            return null

        parentUrl + '/' + @urlPart + '/'

    destroy: ->
        @parent = null

    emit: (args...) -> @trigger args...
