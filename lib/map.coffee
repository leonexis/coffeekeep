exports.rooms =
    '100':
        title: 'The Void'
        desc: 'You are in the middle of nothingness.'
        links:
            south:
                room: 200
    '200':
        title: 'Outside the Void'
        desc: 'Somehow you got outside the void.'
        links:
            north:
                room: 100

areaData =
    id: 'samplearea'
    title: 'Sample Area'
    rooms: exports.rooms

class Area
    constructor: (@data) ->
        {@id, @title, @description} = @data
        rooms = @data.rooms
        console.log "Loading area #{@id} with #{rooms} rooms..."
        @rooms = {}
        for id, data of rooms
            room = new Room @, id, data
            @rooms[id] = room

    getRoom: (id, callback) ->
        if not @rooms[id]?
            callback new Error("Room #{id} does not exist")

        callback null, @rooms[id]

    getRoomList: (callback) ->
        rooms = []
        for id, room of @rooms
            rooms.push [id, room.title]
        callback null, rooms

class Room
    constructor: (@area, @id, data) ->
        {@title, @description, @links} = data
        console.log "Loading room #{@id} in area #{@area}..."

exports.area = new Area areaData

