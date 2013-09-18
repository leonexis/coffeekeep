{Model, Collection} = require './'
{RoomCollection} = require './room'

exports.Area = class Area extends Model
    initialize: ->
        @rooms = new RoomCollection()

exports.AreaCollection = class AreaCollection extends Collection
    model: Area
