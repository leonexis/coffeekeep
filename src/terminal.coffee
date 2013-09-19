###
Web-based Mud Client Service
###
io = require 'socket.io'
{EventEmitter} = require 'events'

exports.MudClientSession = class MudClientSession
    constructor: (@service, @term) ->
        # TODO: create mud session
        @term.on 'disconnect', =>
            @onDisconnect
        
        @term.on 'data', (data) =>
            @onTermData data
        
        #@mud.on 'data', (data) =>
        #    @onMudData data
        
        #@mud.on 'disconnect', =>
        #    @onMudDisconnect
        
        @term.emit 'data', "Connected to Mud Client from #{@term.id}\r\n"
    
    onDisconnect: ->
        #@mud.disconnect()
        @service.unregisterSession @
    
    onTermData: (data) ->
        #@mud.write 'data', data
    
    onMudData: (data) ->
        @term.emit 'data', data
    
    onMudDisconnect: ->
        @term.emit 'data', '\n\nConnection terminated by server'
        @term.disconnect()

exports.MudClientService = class MudClientService
    constructor: (@service) ->
        @service.on 'connection', (socket) =>
            @registerSession socket
        @sessions = {}
    
    registerSession: (socket) ->
        session = new MudClientSession @, socket
        @sessions[socket.id] = session 
    
    unregisterSession: (session) ->
        delete @sessions[session.term.id]

