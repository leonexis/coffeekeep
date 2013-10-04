{Model, Collection} = require './'

exports.Room = class Room extends Model
    getArea: ->
        @collection.parent

    getLocationId: ->
        "#{@getArea().id}##{@id}"

    toString: ->
        "[room #{@getLocationId()}]"

    getMobs: ->
        mobs = []
        here = @getLocationId()
        mobs = @world.users.filter (mob) =>
            mob.get('currentLocation') is here

exports.RoomCollection = class RoomCollection extends Collection
    model: Room
    urlPart: 'rooms'
