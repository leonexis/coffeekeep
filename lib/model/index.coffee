backbone = require 'backbone'
util = require 'util'
_ = require 'underscore'

exports.Model = class Model extends backbone.Model
    url: ->
        # TODO make sure that id is urlescaped!
        if not @collection?
            console.error "Tried to get url for #{util.inspect @}, but no collection"
            return null
        containerUrl = _.result @collection, 'url'
        containerUrl + @id
    
exports.Collection = class Collection extends backbone.Collection
    constructor: (@parent, args...) ->
        @on 'add', (model, collection, options) =>
            return unless collection is @
            model.world = collection.parent?.world
        
        @on 'remove', (model, collection, options) =>
            return unless collection is @
            model.world = null
        
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
