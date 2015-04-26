readline = require './readline'
async = require 'async'
_ = require 'underscore'
{EventEmitter} = require 'events'
{splitFull} = require './util'
{format} = require './format'
{User} = require '../coffeekeep.model/user'
{World} = require '../coffeekeep.model/world'
util = require 'util'

exports.MudSession = class MudSession extends EventEmitter
  # TODO: allow "frontend" between mud session and terminal, for example
  # using blessed for curses support
  constructor: (@service, @socket) ->
    @world = @service.world
    @log = new @service.imports.log.Logger => @toString()
    @user = null #@world.users.first()
    #@user.addSession @
    @inputMode = 'login'
    @promptDirty = false
    @inCommand = false

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
          @processCommand line, (error) =>
            if error?
              @write "Error while processing command '#{line}':
                #{error.toString()}"
              @log.error "Error while processing command '%s'", line, error
              do @updatePrompt
        else
          # Blank line, redisplay prompt
          do @updatePrompt
      catch error
        @write "Error while processing command '#{line}': #{error.toString()}"
        @log.error "Error while processing command: '%s'", line, error
        do @updatePrompt

    @rl.on 'SIGINT', -> true
    @rl.on 'SIGTSTP', -> true
    @rl.on 'SIGCONT', -> true

    @on 'login', =>
      @log.info "User logged in"
      @user.getLocation()
      @processCommand 'l'

    @socket.once 'close', =>
      @log.info "Socket #{@socket} closed session for
        #{@user?.id or '(not logged in)'}"
      @user?.removeSession @
      @inputMode = 'closed'
      @emit 'close'

    do @promptForLogin

  promptForLogin: ->
    @rl.question "What is thy name, oh fearless coder? ", (username) =>
      # Does user exist?
      username = do username.toLowerCase
      if /[^a-z]/.test username
        @write "Thy name must only contain letters and no spaces.\r\n"
        do @promptForLogin
        return

      user = @world.users.get username
      if user?
        @rl.setEcho off
        @rl.question "And what is thy secret passphrase? ", (password) =>
          @rl.setEcho on
          if user.checkPassword password
            @user = user
            @user.addSession @
            @inputMode = 'normal'
            @emit 'login', user
            return
          else
            @write "You can't fool me!\r\n\r\n"
            # TODO: show connection information like IP for telnet
            @log.warn "Failed login attempt for user %s from %s",
              username, @socket?.term?.conn?.remoteAddress
            do @promptForLogin
            return
      else
        if username.length < 4
          @rl.write "That name is too short.\r\n\r\n"
          do @promptForLogin
          return
        @write "I have not heard of any tales or legends of #{username}.\r\n"
        @rl.question "Are you new to these lands? ", (response) =>
          if response[0] in ['y', 'Y']
            @write "Then welcome, new hero!\r\n"
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
            @write "Ah, then I must have misheard your name, hero.\r\n\r\n"
            do @promptForLogin

  promptForNewPassword: (username, callback) ->
    @rl.setEcho off
    @rl.question "By what phrase do you wish to validate your identity? ",
      (password) =>
        @rl.setEcho on
        if password.length < 6
          @write "I'm sorry, but anyone could guess that. Perhaps
   something a bit longer?\r\n"
          @promptForNewPassword username, callback
          return
        @rl.setEcho off
        @rl.question "Could you repeat that to make sure I have it right? ",
          (confirmPassword) =>
            @rl.setEcho on
            if confirmPassword == password
              @write "I'll know you by that phrase then.\r\n"
              callback password
              return
            else
              @write "I must not have gotten that right.\r\n"
              @promptForNewPassword username, callback
              return

  readlineCompleter: (line, callback) ->
    context =
      session: @

    switch @inputMode
      when 'normal' then @user.readlineCompleter context, line, (err, data) =>
        if err?
          @log.error "error in readlineCompleter", err
        callback err, data
      else [[], line]

  updatePrompt: ->
    prompt = "%c#{@user.get 'currentLocation'}%y>%. "
    color = format prompt
    @rl.setPrompt color
    @rl.prompt()

  processCommand: (command, callback) ->
    @inCommand = true
    context =
      session: @

    callback ?= ->

    @user.doCommand context, command, (err, args...) =>
      @inCommand = false
      if @promptDirty
        @updatePrompt()
        @promptDirty = false
      callback err, args...

  write: (data) ->
    @socket.write data

  print: (data...) ->
    if not @promptDirty
      if @isTTY
        # Go to the beginning of the line, clear the line, assuming
        # the current line is the prompt...
        @socket.write '\x1b[0G\x1b[2K'
      else
        @socket.write '\r\n'

      @rl.needsRefresh = true
      @promptDirty = true
    @socket.write data + '\r\n'

    if not @inCommand
      # Unprovoked print to the session, like a chat or fight message
      # refresh the prompt afterwards
      @rl.needsRefresh = false
      do @rl._refreshLine
      @promptDirty = false

  setPrompt: (prompt) -> @rl.setPrompt prompt, length
  prompt: -> @rl.prompt
  question: (query, callback) -> @rl.question query, callback
  setEcho: (echo) -> @rl.setEcho echo
  toString: ->
    # TODO: remoteAddress on telnet
    "[MudSession for #{@user?.id or '(new)'} on
      #{@socket?.term?.conn?.remoteAddress}]"


exports.MudService = class MudService extends EventEmitter

  constructor: (@options, @imports) ->
    @log = new @imports.log.Logger "MudService"
    @sessions = []
    @running = false
    @world = @imports.world
    @world.commands = @imports.commands
    @world.interpreter = @imports.interpreter

  createSession: (socket) ->
    session = new MudSession @, socket
    session.once 'close', =>
      @sessions = _(@sessions).without session

    @sessions.push session


exports.startMud = (options, imports) ->
  # FIXME: This appears to not be used
  {world, log} = imports
  _log = new log.Logger "coffeekeep.core:startMud"
  _.defaults options,
    host: process.env.IP ? '0.0.0.0'
    port: process.env.PORT ? 8080
    telnetPort: process.env.TELNET_PORT ? 5555

  optimist = require 'optimist'
  {app, httpServer} = require './app'

  async.series [
    (cb) ->
      # Create web service
      io = require 'socket.io'
      {MudClientService} = require './terminal'
      mudService = new MudService imports

      mudClientIO = io.listen(httpServer, log: false).of '/mudClient'
      mudClientService = new MudClientService mudService, mudClientIO

      _log.notice "Starting web services: #{JSON.stringify options.web}"
      try
        httpServer.listen options.web.port, options.web.host, ->
          _log.notice "Started web service at
            #{options.web.host}:#{options.web.port}"
          do cb
      catch err
        _log.error "Error while starting web services", err
        do cb err
  ], ->
    _log.notice "Startup complete"

  world
