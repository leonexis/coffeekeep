{Model, Collection} = require './'
{RoomCollection} = require './room'
{MobCollection} = require './mob'

exports.Area = class Area extends Model
    initialize: ->
        @rooms = new RoomCollection()
        # Each area handles all mobs, items, etc with accessors on the room
        # class object
        @mobs = new MobCollection() # Includes Users

exports.AreaCollection = class AreaCollection extends Collection
    model: Area