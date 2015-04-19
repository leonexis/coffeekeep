{EventEmitter} = require 'events'
async = require 'async'
_ = require 'underscore'
util = require 'util'
{Command, CommandCollection} = require './command.coffee'

class InterpreterPlugin extends EventEmitter
    constructor: (@options, @imports) ->
        @log = @imports.log
        @debug = @options.debug ? false
        @imports.model.register "command", Command, CommandCollection
        @commands = new CommandCollection @imports.world
        @imports.world.commands = @commands
        @providers = []
        @register @commands

    register: (provider) ->
        @log.info "interpreter: Registering provider #{provider.toString()}"
        @providers.push provider
        provider.on 'updateCommands', => @updateCommands()
        @updateCommands()

    doCommand: (context, commandStr, callback) ->
        @log.debug "interpreter.doCommand: '#{commandStr}', #{util.inspect context, depth:1}" if @debug
        [verb, args...] = commandStr.split /\s+/
        if not verb? or verb is ""
            return callback null, false

        provider = @reverseCache[verb]?.provider
        @log.debug "interpreter.doCommand: Using provider #{provider}" if @debug
        if not provider?
            context.mob.print "I don't know how to #{verb}."
            # TODO: Continue here
            return callback null, false

        provider.doCommand context, commandStr, callback

    readlineCompleter: (context, line, callback) ->
        @log.debug "interpreter.readlineCompleter: '#{line}', #{util.inspect context, depth:1}" if @debug
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
            (provider, cb) =>
                return cb null, [] if not provider.readlineCompleter?
                provider.readlineCompleter context, line, (err, [hits, line]) =>
                    return cb err if err?
                    cb null, hits
            (err, hits) =>
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
        for provider in @providers
            for command in provider.getCommands()
                command.provider = provider
                commands.push command

        @log.debug "getCommand responses: #{util.inspect commands}" if @debug
        @commandCache = _.flatten commands
        @log.debug "New command cache: #{util.inspect @commandCache, depth: 2}" if @debug

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
        @log.debug "verbsForMob #{mob.id}: #{util.inspect verbs, depth: 1}" if @debug
        verbs

module.exports = (options, imports, register) ->

    interpreterPlugin = new InterpreterPlugin options, imports
    register null,
        interpreter: interpreterPlugin
        commands: interpreterPlugin.commands