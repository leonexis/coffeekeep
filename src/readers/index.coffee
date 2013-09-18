###
Base class for reading Area files from different MUD formats. The base
class reads from a JSON file to serve as an example. Uses the event system.

Events: `area`, `room`

###
events = require 'events'

class AreaReader extends events.EventEmitter
    read: (file) ->
        areaFile = require(file)
        console.log "AreaReader: #{JSON.stringify areaFile}"
        if not areaFile?
            return
            
        area =
            id: areaFile.id
            title: areaFile.title
            description: areaFile.description
        
        @emit 'area', area
        
        if areaFile.rooms?
            for id, room of areaFile.rooms
                room.id = id
                @emit 'room', room
        
        @emit 'done'

exports.AreaReader = AreaReader