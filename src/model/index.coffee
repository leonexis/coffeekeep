backbone = require 'backbone'

exports.Model = class Model extends backbone.Model

exports.Collection = class Collection extends backbone.Collection
    constructor: (@parent) ->
        super()

    destroy: ->
        @parent = null

    add: (data, args...) ->
        if not @model? or data instanceof backbone.Model
            return super data, args...
        
        unless data instanceof backbone.Model
            model = new @model data
        
        model.world = @parent.world
        return super model, args...