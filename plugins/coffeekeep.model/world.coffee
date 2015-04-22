util = require 'util'
async = require 'async'
{Model, Collection} = require './base'
{Area, AreaCollection} = require './area'
{Room} = require './room'
{UserCollection} = require './user'
debug = require 'debug'

exports.World = class World extends Model
    debug: debug 'coffeekeep.model:World'
    url: '/world'
    defaults:
        startLocation: "default#start"
        title: "CoffeeKeep"

    toString: -> "[#{@constructor.name} #{@get 'title'}]"
    initialize: ->
        @areas = new AreaCollection @
        @users = new UserCollection @
        @world = @

    startup: (cb) ->
        @loadCollections cb

    loadCollections: (callback) ->
        async.parallel [
            (cb) =>
                @users.fetch
                    success: =>
                        @log.info "Loaded %d users", @users.length
                        do cb
                    error: (err) =>
                        cb err
            (cb) =>
                @areas.fetch
                    success: =>
                        @log.info "Loaded %d areas", @areas.length
                        do cb
                    error: (err) =>
                        cb err
        ], (err) =>
            if err
                @log.error "Error while loading collections", err
                return callback err

            @log.info "loadCollections complete"
            if @areas.length is 0
                @log.info "There are no areas loaded. Let me make one for you."
                return @createStarterArea callback
            do callback

    createStarterArea: (callback) ->
        ###
        async.waterfall [
            (cb) =>
                console.log "Creating a new area"
                area = new Area
                    id: "default"
                    title: "Default Area"

                @areas.create area,
                    success: (area) ->
                        cb null, area
                    error: (err) ->
                        cb err

            (area, cb) =>
                console.log "Creating a new room"
                room = new Room
                    id: "start"
                    title: "A new room"
                    description: "The is a new room for your new mud."

                area.vrooms.create room,
                    success: (room) ->
                        iroom = room.getClone()
                        areas.rooms.add iroom
                            success: (iroom) ->
                                cb null, iroom
                            error: (err) ->
                                cb err
                    error: (err) ->
                        cb err

            (room, cb) =>
                console.log "Setting new room as the world start location"
                @world.set 'startLocation', do room.getLocationId
                cb null
        ], (err) ->
            callback err
        ###
        @log.info "Creating a new area"
        area = new Area
            id: "default"
            title: "Default Area"
        @areas.add area
        vroom = new Room
            id: "1"
            title: "A new room"
            description: "This is a new room for your new MUD."
        area.vrooms.add vroom
        room = vroom.cloneVirtual()
        area.rooms.add room
        @log.info "Setting new room as the world start location"
        @world.set 'startLocation', room.getLocationId()
        callback null

    getStartRoom: ->
        loc = @world.get 'startLocation'
        if loc?
            [areaId, roomId] = loc.split "#"
            area = @areas.get areaId
            if area?
                room = area.rooms.get roomId
                if room?
                    return room

        @log.error "Could not load the start location, trying first room of first area."

        area = @areas.first()
        if not area?
            throw new Error "Could not find any areas in the world"
        room = area.rooms.first()
        if not room?
            throw new Error "Could not find any rooms in #{area.toString()}"
        room

    # Get location by specified string ID. Can be full form (school.are#3700)
    # or just a room ID, in which case it will search all areas for the id.
    # This allows for importing other style MUD formats that only point
    # to room IDs. Also, specifying an area ID will get the first room of that
    # area. Returns the room object.
    getLocationById: (roomId, area=null) ->
        if '#' in roomId
            [areaId, roomId] = roomId.split '#'
            return @areas.get(areaId)?.rooms.get(roomId)

        room = null
        if area
            room = area.rooms.get roomId

        if not room?
            @areas.forEach (area) =>
                return if room
                if area.id == roomId
                    room = area.rooms.first()
                else
                    room = area.rooms.get roomId

        room

    # Given a locationId with either/both area and room id, get the final
    # location id
    resolveLocationId: (locationId) ->
        return locationId if '#' in locationId
        room = @getLocationById locationId
        room?.getLocationId()
