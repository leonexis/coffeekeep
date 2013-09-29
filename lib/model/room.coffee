{Model, Collection} = require './'

exports.Room = class Room extends Model
    getArea: ->
        @collection.parent
        
    getLocationId: ->
        "#{@getArea().id}##{@id}"
        
    toString: ->
        "[room #{@getLocationId()}]"

exports.RoomCollection = class RoomCollection extends Collection
    model: Room
    urlPart: 'rooms'
