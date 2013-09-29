readline = require 'readline'
async = require 'async'
_ = require 'underscore'
{EventEmitter} = require 'events'
{splitFull} = require './util'
{format} = require './format'
{User} = require './model/user'
{World} = require './model/world'

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
                @write "Error while processing command '#{line}': #{error.toString()}"
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
    

exports.startMud = (options={}) ->
    _.defaults options,
        plugins: 
            './core/storage/sqlite':
                database: "#{__dirname}/../coffeekeep.sqlite"
        web:
            host: process.env.IP ? '0.0.0.0'
            port: process.env.PORT ? 8080
        telnet:
            host: process.env.IP ? '0.0.0.0'
            port: process.env.TELNET_PORT ? 5555
    
    optimist = require 'optimist'    
    {app, httpServer} = require './app'
    p = require '../package.json'
    console.log "Starting CoffeeKeep #{p.version}"
    
    world = null
    async.series [
        (cb) ->
            # Load plugins
            console.log "Loading plugins"
            for plugin, opts of options.plugins
                console.log "Starting plugin #{plugin}"
                mod = require plugin
                mod.enable? opts
            do cb
            
        (cb) ->
            # Load our world
            console.log "Loading coffeekeep world"
            
            world = new World()
            world.fetch
                success: -> do cb
                error: (err) -> cb err
        
        (cb) ->
            # Call world startup
            console.log "Triggering world startup"
            world.startup (err) ->
                cb err
        
        (cb) ->
            # Create web service
            io = require 'socket.io'
            {MudClientService} = require './terminal'
            app.set 'coffeekeep world', world

            mudService = new MudService world
            
            mudClientIO = io.listen(httpServer, log: false).of '/mudClient'
            mudClientService = new MudClientService mudService, mudClientIO
            
            console.log "Starting web services: #{JSON.stringify options.web}"
            try
                httpServer.listen options.web.port, options.web.host, ->
                    console.log "Started web service at #{options.web.host}:#{options.web.port}"
                    do cb
            catch err
                console.error "Error while starting web services: #{err}"
                do cb err
    ], ->
        console.log "Startup complete"
    
    world
    