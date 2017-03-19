_ = require 'lodash'
util = require 'util'
path = require 'path'

module.exports = (options, imports, register) ->
  {log, model, world, mud} = imports
  options.channels ?= {}

  class Message
    ###
    ## Message Format
    Tokens surrounded by `{}` are replaced with the appropriate term that
    represents the subject. If the token is prepended by `^`, the token refers
    to the target. The capitalization of the first letter determines if the
    replaced term should also be initially capitalized.

     - `{he}` - He, She, Zhe, It, or You
     - `{his}` - His, Her, Zher, Its, or Your
     - `{him}` - Him, Her, Zher, It, or You
     - `{himself}` - Himself, Herself, Zherself, Yourself
     - `{hisself}` - Hisself, Herself, Zherself, Yourself
     - `{name}` - You, or the Name
     - `{nameself}` - Yourself, or the Name
     - `{name's}` - Name's or Your
     - `{is}` - Is, or Are
     - `{has}` - Has, or Have
     - `{s}`, `{es}` - Shown if previous token was not the observer

    ## Combinations

     - `{He} hit {himself}` - `You hit yourself`, `He hit himself`
     - `{He} hit {^him}` - `You hit him`, `He hit you`, `He hit him`
     - `{Name} maim{s} {^name}` - `Leonexis maims a goblin`, `You maim a goblin`, `Leonexis maims you`

    ## Data variables
    The message format string can output text provided in @data, such as
    the text of a chat message:

     - `{Name} gossip{s}, "{text}"` - `Leonexis gossips, "<value of @data.text>"`
    ###

    @termsByGender:
      he: ['it', 'he', 'she', 'zhe', 'you']
      his: ['its', 'his', 'her', 'zher', 'your']
      him: ['it', 'him', 'her', 'zher', 'you']
      himself: ['itself', 'himself', 'herself', 'zherself', 'yourself']
      hisself: ['itself', 'hisself', 'herself', 'zherself', 'yourself']

    constructor: (@data) ->
      {@message, @toOther, @toSubject, @toTarget, @observer, @subject,
       @target, @channel} = @data
      if @message?
        @toOther ?= @message
        @toSubject ?= @message
        @toTarget ?= @message

      @tokens =
        toOther: @parse @toOther
        toSubject: @parse @toSubject
        toTarget: @parse @toTarget

      @_tokensCache =
        toOther: @toOther
        toSubject: @toSubject
        toTarget: @toTarget

    token: (token) ->
      isFirstCap = token[0] isnt token[0].toLowerCase()
      token = token.toLowerCase()

      log.debug "Message(#{@message}).token: #{token}" if options.debug

      if @data.hasOwnProperty(token) and @data[token]?
        return @data[token]

      switch token
        when 'is'
          return 'are' if @lastObserver
          return 'is'
        when 'has'
          return 'have' if @lastObserver
          return 'has'
        when 's', 'es'
          return '' if @lastObserver
          return token

      subject = @subject
      isObserver = @observer is @subject
      if token[0] is '^'
        token = token[1..]
        subject = @target
        isObserver = @observer is @target

      if not subject?
        return '???'

      @lastObserver = isObserver
      terms = Message.termsByGender[token]
      term = null
      if terms?
        term = terms[subject.gender % 4]
        term = terms[4] if isObserver
      else
        if isObserver
          term = switch token
            when 'name' then 'you'
            when 'nameself' then 'yourself'
            when "name's" then 'your'
            when 'is' then 'are'
        else
          term = switch token
            when 'name' then subject.get 'name'
            when 'nameself' then subject.get 'name'
            when "name's" then "#{subject.get 'name'}'s"


      if isFirstCap and term.length >= 1
        term = term[0].toUpperCase() + term[1..]

      term

    parse: (msg) ->
      tokens = []
      while msg.length > 0
        n = msg.indexOf '{'
        token = '{'
        if n is -1
          tokens.push msg
          return tokens

        if n > 0
          tokens.push msg[...n]

        msg = msg[n+1..]
        n = msg.indexOf '}'
        if n is -1
          tokens[tokens.length-1] = tokens[tokens.length-1] + token + msg
          return tokens

        tokens.push
          token: token
          data: msg[...n]

        if n+1 >= msg.length
          msg = ''
          continue

        msg = msg[n+1..]

      tokens

    updateTokenCache: ->
      for msg in ['toSubject', 'toObserver', 'toOther']
        if @_tokensCache[msg] isnt @[msg]
          @tokens[msg] = @parse @[msg]

    forObserver: (observer) ->
      oldObserver = @observer
      @observer = observer
      @updateTokenCache()

      msg = 'toOther'
      if @observer is @subject
        msg = 'toSubject'
      else if @observer is @target
        msg = 'toTarget'

      out = ""
      for token in @tokens[msg]
        if token.token?
          out += @token token.data
        else
          out += token

      @observer = oldObserver
      out

    toString: -> @forObserver @observer

    toJSON: ->
      out =
        subject: @subject?.id
        target: @target?.id
        observer: @observer?.id
        channel: @channel?.id
        message: @message
        toSubject: @toSubject
        toTarget: @toTarget
        toOther: @toOther

      _.defaults out, @data

  class Channel extends model.models.base
    defaults:
      acl: "+all"
      description: null
      command: null
      playerMustEnable: false   # Player must explicitly enable channel
      maxHistory: 100       # Keep at most this many messages
      format: null

    initialize: ->
      @history = []

    toString: -> "[Channel '#{@id}']"

    reMessage: /^(\S+)\s+(.*)$/
    reList: /^(\S+)\s+list(\s+\d+)?$/

    processMessage: (message) ->
      message = new Message message if message not instanceof Message
      maxHistory = @get 'maxHistory'
      if maxHistory > 0
        @history.push message.toJSON()
        while @history.length > @get 'maxHistory'
          @history.shift()
      else if maxHistory == 0
        # In case max history was just changed, ensure we remove if
        # we no longer need history
        @history.shift() while @history.length > 0

      for session in mud.sessions
        continue unless session.user?
        continue unless @isEnabled {mob:session.user}
        acl = @get 'acl'
        if acl? and acl isnt '+all'
          continue unless session.user.hasPermission acl
        session.user.emit 'message', message
        session.user.print message.forObserver session.user

    enable: (context, cb) ->
      return if @isEnabled context
      {mob} = context

      clist = mob.get 'channels'
      clist ?= {}
      clist[@id] = true
      mob.set 'channels', clist
      cb? null

    disable: (context, cb) ->
      return unless @isEnabled context
      {mob} = context

      clist = mob.get 'channels'
      clist ?= {}
      clist[@id] = false
      mob.set 'channels', clist
      cb? null

    isEnabled: (context) ->
      return false unless @checkACL context
      {mob} = context

      clist = mob.get 'channels' ? {}
      if clist[@id] is undefined
        return not @get 'playerMustEnable'
      clist[@id]

    checkACL: (context) ->
      return true if not acl? or acl is "+all"

      log.error "Custom acl on channel #{@.id}, but not implemented!"
      false

    getHistory: (lines, context) ->
      if context?
        return null unless @checkACL context

      if lines > @history.length
        lines = @history.length

      if lines <= 0
        return []

      @history[@history.length - lines..]

    doCommand: (context, commandStr, cb) ->
      {mob} = context
      relst = @reList.exec commandStr
      remsg = @reMessage.exec commandStr
      if relst?
        [m, lines] = relst
        if lines?
          lines = Number lines
        else
          lines = @history.length

        history = @getHistory lines, context
        mob.print "Chat log for #{@id}"
        for message in history
          mob.print "#{message.subject}> #{message.text}"

        return setImmediate -> cb null, true

      unless @isEnabled context
        mob.print "You can't send a message, you have this channel disabled!"
        return setImmediate -> cb null, false

      if not remsg?
        mob.print "Must provide a message."
        return setImmediate -> cb null, false

      [m, verb, text] = remsg

      message = new Message
        message: @get 'format'
        text: text
        subject: context.mob
        channel: @

      @processMessage message
      setImmediate -> cb null, true

  class ChannelCollection extends model.collections.base
    model: Channel

    intialize: ->
      @parent.on 'channel.message', (message) =>
        @processMessage message

      _update = (model, collection, options) =>
        return unless collection is @
        @emit 'updateCommands'

      @on 'add', _update
      @on 'remove', _update
      @on 'reset', _update
      @on 'destroy', _update

    toString: -> "[ChannelCollection of #{@parent}]"

    register: ->
      interpreter.register @

    getCommands: ->
      @map (channel) ->
        verb: channel.id
        aliases: ['no'+channel.id]
        category: 'chat'
        acl: channel.get 'acl'
        description: "Sends a message on the #{channel.id} channel"
        help: """
Usage: #{channel.id} <message>
       #{channel.id} list [# of lines]
       #{channel.id}
       no#{channel.id}

With an argument, #{channel.id} sends a message on that channel.

Calling with 'list' will list the history of the channel up to the number
specified or the maximum history length if no number was specified.

Using #{channel.id} or no#{channel.id} with no argument enables or disables
receiving messages on that channel, respectively.
        """

    processMessage: (message) ->
      if not message.channel?
        log.error "No channel provided for message: #{util.inspect message}"
        return

      msgObj = new Message message

    doCommand: (context, commandStr, cb) ->
      [verb, args...] = commandStr.split /\s+/
      {mob} = context
      verb = verb.toLowerCase()
      channel = @get verb
      isDisabler = false
      if not channel? and verb.indexOf('no') == 0
        channel = @get verb[2..]
        isDisabler = true

      if args.length is 0
        # Enable or disable channel
        if isDisabler
          if channel.isEnabled context
            mob.print "Channel #{channel.id} disabled."
            return channel.disable context, cb
          else
            mob.print "Channel #{channel.id} was already disabled."
            return setImmediate cb
        else
          unless channel.isEnabled context
            mob.print "Channel #{channel.id} enabled."
            return channel.enable context, cb

      channel.doCommand context, commandStr, cb

  model.register 'channel', Channel, ChannelCollection
  world.channels = new ChannelCollection imports.world

  # Register the channels provided in configuration
  log.info "Registering message channels"
  for id, opts of options.channels
    log.debug "Registering channel: #{id}"
    _.defaults opts, id: id
    world.channels.add opts

  imports.interpreter.register world.channels

  messaging =
    Message: Message
    channels: world.channels

  world.commands.loadDirectory path.join(__dirname, 'commands'),
    messaging: messaging

  register null, messaging: messaging
