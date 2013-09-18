{Model, Collection} = require './'
{AreaCollection} = require './area'

exports.World = class World extends Model
    initialize: ->
        @areas = new AreaCollection()
        