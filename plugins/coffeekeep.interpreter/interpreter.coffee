{EventEmitter} = require 'events'
async = require 'async'
_ = require 'underscore'
util = require 'util'
{Command, CommandCollection} = require './command.coffee'

class InterpreterPlugin extends EventEmitter
  constructor: (@options, @imports) ->
    @log = new @imports.log.Logger => @constructor.name
    @debug = @options.debug ? false
    @imports.model.register "command", Command, CommandCollection
    @commands = new CommandCollection @imports.world
    @imports.world.commands = @commands
    @providers = []
    @register @commands

  register: (provider) ->
    @log.info "Registering provider #{provider.toString()}"
    @providers.push provider
    provider.on 'updateCommands', => @updateCommands()
    @updateCommands()

  doCommand: (context, commandStr, callback) ->
    @log.silly "doCommand: '%s', %s", commandStr, context
    [verb, args...] = commandStr.split /\s+/
    if not verb? or verb is ""
      return callback null, false

    provider = @reverseCache[verb]?.provider
    @log.debug "doCommand: Using provider #{provider}" if @debug
    if not provider?
      context.mob.print "I don't know how to #{verb}."
      # TODO: Continue here
      return callback null, false

    provider.doCommand context, commandStr, callback

  readlineCompleter: (context, line, callback) ->
    @log.silly "readlineCompleter: '%s', %s", line, context
    [verb, args...] = line.split /\s+/
    hits = []
    verbs = @verbsForMob context.mob
    if args.length == 0
      if not verb? or verb is ""
        return callback null, [verbs, line]

      for verb in @verbsForMob context.mob
        hits.push verb if verb.indexOf(line) == 0

      return callback null, [hits, line]

    async.map @providers,
      (provider, cb) ->
        return cb null, [] if not provider.readlineCompleter?
        provider.readlineCompleter context, line, (err, [hits, line]) ->
          return cb err if err?
          cb null, hits
      (err, hits) ->
        return callback err if err?
        hits = _.flatten hits
        callback null, [hits, line]

  ###
  Get full command list in the form Array<Object> with fields:

   - `verb` - Command verb
   - `aliases` - Aliases of commands
   - `category` - chatting, fighting, etc
   - `acl` - required permissions to show/use

  This is used for initial command completion
  ###
  updateCommands: ->
    commands = []
    @log.debug "updateCommands called"
    for provider in @providers
      for command in provider.getCommands()
        @log.silly "updateCommands: command '%s' ('%s'), category: '%s',
          acl: '%s'", command.verb, command.aliases, command.category,
          command.acl
        command.provider = provider
        commands.push command

    @commandCache = _.flatten commands
    @log.silly "New command cache: %j", @commandCache

    @reverseCache = {}
    for command in @commandCache
      @reverseCache[command.verb] = command
      if command.aliases?
        for alias in command.aliases
          @reverseCache[alias] = command

  verbsForMob: (mob, includeAliases=true) ->
    seen = {}
    verbs = []
    for command in @commandCache
      if command.acl?
        res = seen[command.acl.toString()]
      if not res?
        seen[command.acl.toString()] = res = mob.hasPermission command.acl
      continue if not res

      verbs.push command.verb
      verbs.push command.aliases if command.aliases? and includeAliases

    verbs = _.flatten verbs
    @log.debug "verbsForMob %s: %j", mob.id, verbs
    verbs

module.exports = (options, imports, register) ->

  interpreterPlugin = new InterpreterPlugin options, imports
  register null,
    interpreter: interpreterPlugin
    commands: interpreterPlugin.commands
