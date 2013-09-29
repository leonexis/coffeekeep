backbone = require 'backbone'
util = require 'util'
async = require 'async'
_ = require 'underscore'

exports.Model = class Model extends backbone.Model
    storedCollections: []
    constructor: (args...) ->
        @lastSync = null
        
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
                @[collection].fetch =>
                    success: =>
                        console.log "Loaded #{@[collection].length} #{collection}"
                        do cb
                    error: (err) =>
                        cb err
            (err) ->
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
