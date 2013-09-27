readline = require 'readline'
{EventEmitter} = require 'events'
{splitFull} = require './util'
{format} = require './format'
{User} = require './model/user'

exports.MudSession = class MudSession extends EventEmitter
    constructor: (@service, @socket) ->
        @world = @service.world
        @user = null #@world.users.first()
        #@user.addSession @
        @inputMode = 'login'
        
        @columns = 80 # TODO: get from terminal, also @emit 'resize' events
        @isTTY = @socket.isTTY
        @rl = new readline.Interface
            input: @socket
            output: @
            completer: (line, callback) =>
                @readlineCompleter line, callback
            
        @rl.on 'line', (line) =>
            return if @inputMode isnt 'normal'
            try
                if line? and line
                    @processCommand line
            catch error
                @write "Error while processing command '#{@line}': #{error.toString()}"
                console.error "Error while processing command: #{error.stack}"
            do @rl.prompt
        
        @rl.on 'SIGINT', -> true
        @rl.on 'SIGTSTP', -> true
        @rl.on 'SIGCONT', -> true
        
        @on 'login', ->
            @updatePrompt()
            @processCommand 'l'
            do @rl.prompt
        
        @socket.on 'close', =>
            console.log "Socket #{@socket} closed session for #{@user?.id or '(not logged in)'}"
            @user?.removeSession @
            @inputMode = 'closed'
        
        do @promptForLogin
        
    promptForLogin: ->
        @rl.question "What is thy name, oh fearless coder? ", (username) =>
            # Does user exist?
            username = do username.toLowerCase
            if /[^a-z]/.test username
                @rl.write "Thy name must only contain letters and no spaces.\r\n"
                do @promptForLogin
                return
        
            user = @world.users.get username
            if user?
                @rl.question "And what is thy secret passphrase? ", (password) =>
                    if user.checkPassword password
                        @user = user
                        @user.addSession @
                        @inputMode = 'normal'
                        @emit 'login', user
                        return
                    else
                        @rl.write "You can't fool me!\r\n\r\n"
                        do @promptForLogin
                        return
            else
                if username.length < 4
                    @rl.write "That name is too short.\r\n\r\n"
                    do @promptForLogin
                    return
                @rl.write "I have not heard of any tales or legends of #{username}.\r\n"
                @rl.question "Are you new to these lands? ", (response) =>
                    if response[0] in ['y', 'Y']
                        @rl.write "Then welcome, new hero!\r\n"
                        @inputMode = 'newuser'
                        @promptForNewPassword username, (password) =>
                            @inputMode = 'normal'
                            user = new User
                                name: username
                            user.world = @world
                            user.setPassword password
                            @world.users.create user
                            @user = user
                            @user.addSession @
                            @emit 'login', user
                        return
                    else
                        @rl.write "Ah, then I must have misheard your name, hero.\r\n\r\n"
                        do @promptForLogin
    
    promptForNewPassword: (username, callback) ->
        @rl.question "By what phrase do you wish to validate your identity? ", (password) =>
            if password.length < 6
                @rl.write "I'm sorry, but anyone could guess that. Perhaps
 something a bit longer?\r\n"
                @promptForNewPassword username, callback
                return
            @rl.question "Could you repeat that to make sure I have it right? ", (confirmPassword) =>
                if confirmPassword == password
                    @rl.write "I'll know you by that phrase then.\r\n"
                    callback password
                    return
                else
                    @rl.write "I must not have gotten that right.\r\n"
                    @promptForNewPassword username, callback
                    return
    
    readlineCompleter: (line, callback) ->
        switch @inputMode
            when 'command' then @world.commands.readlineCompleter line, callback
            else [[], line]
    
    updatePrompt: ->
        prompt = "#%c#{@user.getLocation().get 'id'}%y>%. "
        color = format prompt
        length = format(prompt, null, false).length
        @rl.setPrompt color, length

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
    
    print: (data...) ->
        @socket.write data + '\r\n'
    
exports.MudService = class MudService extends EventEmitter
    constructor: (@world) ->
        @sessions = []
    
    createSession: (socket) ->
        session = new MudSession @, socket
        @sessions.push session
    