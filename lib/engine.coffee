{EventEmitter} = require 'events'
{splitFull} = require './util'

exports.MudSession = class MudSession extends EventEmitter
    constructor: (@service, @socket) ->
        @world = @service.world
        @user = @world.users.first()
        @user.addSession @
        @state = 'new'
        @echo = true
        @commandMode = true
        @buffer = ""
        @history = []
        @inCommand = false
    
        @socket.on 'data', @processData
        @processCommand 'l'
        @writePrompt()
        
    processData: (data) =>
        # Split control characters and text
        for c in data
            code = c.charCodeAt()
            if 127 > code > 31
                @buffer += c
                if @echo
                    @write c
                continue
        
            if @commandMode and code == 13
                if @echo
                    @write '\r\n'
                try
                    @processCommand @buffer
                catch error
                    @write "Error while processing command '#{@buffer}': #{error.toString()}"
                    console.error "Error while processing command: #{error.stack}"
                @writePrompt()
                @buffer = ""
                continue
        
    writePrompt: ->
        @write "\n##{@user.getLocation().get 'id'}> "

    processCommand: (command) ->
        @user.doCommand command
        
    processCommandOld: (command) ->
        command = command.split()
        location = @user.getLocation()
        switch command[0]
            when 'l', 'look'
                @print "#{location.get 'title'}"
                @print "#{location.get 'description'}"
                @write " exits: "
                for direction, link of location.get 'links'
                    @write "#{direction} "
                @print ''
            when 'exits'
                @print "Exits:"
                for direction, link of location.get 'links'
                    @write " #{direction} - #{link.description ? 'Nothing special\r\n'}"
            when 'n', 'e', 's', 'w', 'u', 'd', 'north', 'easth', 'south', 'west', 'up', 'down'
                direction = switch command[0]
                    when 'n' then 'north'
                    when 'e' then 'east'
                    when 's' then 'south'
                    when 'w' then 'west'
                    when 'u' then 'up'
                    when 'd' then 'down'
                    else command[0]
                
                links = location.get 'links'
                if not links[direction]?
                    @print "You can't go that way."
                else
                    link = links[direction]
                    newRoom = location.area.rooms.get link.room
                    if not newRoom
                        @print "Room not available!"
                    else
                        @user.setLocation newRoom
                        location = newRoom
                        @processCommand 'l'
            when 'goto'
                if command.length != 2
                    @print "Must specify room number."
                newRoom = location.area.rooms.get command[1]
                if not newRoom?
                    @print "Room not loaded."
                else
                    @user.setLocation newRoom
                    location = newRoom
                    @proceesCommand 'l'
    
    write: (data) ->
        @socket.write data
    
    print: (data) ->
        @socket.write data + '\r\n'
    

exports.MudService = class MudService extends EventEmitter
    constructor: (@world) ->
        @sessions = []
    
    createSession: (socket) ->
        session = new MudSession @, socket
        @sessions.push session
    