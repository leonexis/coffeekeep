{Model, Collection} = require './'

exports.Room = class Room extends Model
    toString: ->
        "[room {@area.get 'id'}##{@get 'id'}]"

exports.RoomCollection = class RoomCollection extends Collection
    model: Room
