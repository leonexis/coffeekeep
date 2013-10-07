{Model, Collection} = require './'

class Room extends Model
    defaults: ->
        links: []
        extras: []

    initialize: ->
        # TODO: convert exits, specials, etc to collections

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

class RoomCollection extends Collection
    model: Room
    urlPart: 'rooms'

exports.Room = Room
exports.RoomCollection = RoomCollection