{Model, Collection} = require './'

exports.Room = class Room extends Model
    getLocationId: ->
        "#{@area.id}##{@id}"
        
    toString: ->
        "[Room #{@getLocationId()}]"

exports.RoomCollection = class RoomCollection extends Collection
    model: Room
    urlPart: 'rooms'
