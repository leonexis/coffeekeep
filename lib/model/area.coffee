{Model, Collection} = require './'
{RoomCollection} = require './room'
{MobCollection} = require './mob'

exports.Area = class Area extends Model
    storedCollections: ['rooms', 'mobs']

    initialize: ->
        @rooms = new RoomCollection @
        # Each area handles all mobs, items, etc with accessors on the room
        # class object
        @mobs = new MobCollection @ # Does not include users (see @world)

    toString: ->
        return "[Area #{@id}]"

exports.AreaCollection = class AreaCollection extends Collection
    model: Area
    urlPart: 'areas'
