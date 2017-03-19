###
Web-based Mud Client Service
###
io = require 'socket.io'
{EventEmitter} = require 'events'

exports.MudClientSession = class MudClientSession extends EventEmitter
  isTTY: true

  constructor: (@service, @term) ->
    super()
    # TODO: create mud session
    @paused = false

    @mud = @service.mudService.createSession @
    @term.on 'disconnect', =>
      @emit 'close'

    @term.on 'data', (data) =>
      @emit 'data', data

  write: (data) ->
    @term.emit 'data', data

  close: ->
    @term.emit 'data', '\n\nConnection terminated by server'
    @term.disconnect()

  resume: ->
    # Resume

  pause: ->
    # Pause


exports.MudClientService = class MudClientService
  constructor: (@mudService, @termService) ->
    @termService.on 'connection', (socket) =>
      @registerSession socket
    @sessions = {}

  registerSession: (socket) ->
    session = new MudClientSession @, socket
    @sessions[socket.id] = session

  unregisterSession: (session) ->
    delete @sessions[session.term.id]

exports.setup = (options, imports, cb) ->
  {mud} = imports
  mudClientIO = io.listen(imports.server, log: false).of '/mudClient'
  mudClientService = new MudClientService mud, mudClientIO
  cb null, mudClientService
