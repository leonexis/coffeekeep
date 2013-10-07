fs = require 'fs'
path = require 'path'
util = require 'util'
coffee = require 'coffee-script'
{splitFull} = require '../util'
{Model, Collection} = require './'
security = require '../security'


exports.Command = class Command extends Model
    idAttribute: 'name'
    defaults:
        name: 'lazy'                    # Primary command name
        acl: '+all'                     # By default, anyone can see
        aliases: []                     # Other command names
        prefixChar: null                # Get anything starting with char
        description: "I don't really do anything"
        help: "Usage: lazy. Dats it"

        action: (context, request) ->
            {mob} = context
            mob.print "The lazy command does nothing."

        completer: (context, request) ->
            [[], request.line]

    toString: -> "[command #{@id}]"

    doCommand: (context, commandStr, callback) ->
        request = @parseCommand context, commandStr

        # Check to make sure we are able to run the command
        if context.mob?
            context.mob.mustHavePermission @getMask()

        action = @get('action')
        if action.length < 3
            try
                result = action context, request
            catch error
                return callback error
            callback null, result
        else
            action context, request, callback

    readlineCompleter: (context, commandStr, callback) ->
        request = @parseCommand context, commandStr

        if context.mob?
            context.mob.mustHavePermission @getMask()

        completer = @get('completer')
        if completer.length < 3
            try
                result = completer context, request
                console.log util.inspect result
            catch error
                return callback error
            callback null, result
        else
            completer context, request, callback

    parseCommand: (context, commandStr) ->
        [verb, args...] = splitFull commandStr
        verb = verb.toLowerCase()
        request =
            verb: verb
            args: args,
            line: commandStr

    getMask: ->
        acl = @get 'acl'
        if @_maskCache isnt acl
            @mask = new security.Mask acl
            @_maskCache = acl
        @mask

exports.CommandCollection = class CommandCollection extends Collection
    loadDirectory: (dirName, cb) ->
        # Load commands from a folder containing commands. Each command file
        # should have `exports.commands` include all commands in the file
        # to be registered
        console.log "Loading commands from #{dirName}"

        success = 0
        fail = 0
        files = fs.readdirSync dirName
        for file in files
            if file[-3..] != '.js' and file[-7..] != '.coffee'
                console.log "Skipping non-command file #{file}"
                continue

            fileName = path.join dirName, file

            if @loadFile fileName
                success += 1
            else
                fail += 1

        console.log "Successfully loaded #{success} out of #{success+fail} commands"
        if fail > 0
            console.error "WARNING: Not all commands loaded successfully. Check configuration."

        do @updateValidCommands

    loadFile: (filename, reload=false) ->
        # Load a command file that exports `exports.commands`
        try
            evalOptions =
                modulename: 'command_' + path.basename filename, '.coffee'
                filename: filename
                sandbox:
                    console: console
                    Command: Command
                    require: (id) ->
                        if id.indexOf('.') == 0
                            id = path.resolve __dirname, '..', id
                        require id

            command = coffee.eval fs.readFileSync(filename, 'utf8'), evalOptions

            base = filename[...filename.lastIndexOf '.']
            unless command instanceof Command
                command = new Command command

            oldCommand = @get command.get 'name'
            if oldCommand?
                if not reload
                    console.error "WARNING: Command '#{command.get 'name'}' already
exists from #{oldCommand.get 'fileName'}. Replacing."
                oldCommand.set command.attributes
                return true

            command.set 'fileName': filename
            @add command
            return true
        catch error
            console.error "Error while loading commands from #{base}: #{error.toString()}"
            console.error error.stack
            return false

    getCommand: (context, verb) ->
        # Check if it is a valid verb.
        if verb not in @maskCheckVerbs context.mob
            return

        commandModel = @get verb
        if not commandModel?
            models = @filter (c) ->
                aliases = c.get 'aliases'
                if not aliases?
                    return

                verb in aliases
            if models.length > 1
                console.error "WARNING: Multiple commands found for alias '#{verb}'"

            return models[0]

        commandModel

    doCommand: (context, commandStr, callback) ->
        [verb, args...] = splitFull commandStr

        commandModel = @getCommand context, verb
        if not commandModel?
            context.mob.print "I don't know how to #{verb}."
            return callback? null, false

        commandModel.doCommand context, commandStr, callback

    updateValidCommands: ->
        console.log "Updating valid commands"
        commands = @pluck 'name'
        aliases = []
        @commandMasks = {}
        @forEach (command) =>
            name = command.get 'name'
            mask = command.getMask()
            @commandMasks[name] = mask
            commandAliases = command.get 'aliases'
            if commandAliases
                for alias in commandAliases
                    @commandMasks[alias] = mask
                aliases = aliases.concat commandAliases

        @validCommands = commands.sort()
        @validAliases = aliases.sort()
        @validVerbs = commands.concat(aliases).sort()

    maskCheckVerbs: (mob) ->
        verbs = []
        seen = {}
        for verb, mask of @commandMasks
            cache = seen[mask.acl]
            if cache?
                verbs.push verb if cache
                continue
            result = mob.hasPermission mask
            seen[mask.acl] = result
            verbs.push verb if result

        verbs.sort()

    readlineCompleter: (context, line, callback) ->
        # TODO: chain completer to command
        #completions = @validVerbs
        completions = @maskCheckVerbs context.mob

        [verb, args...] = splitFull line
        if verb? and args.length > 0
            commandModel = @getCommand context, verb
            if not commandModel?
                return [[], line]
            return commandModel.readlineCompleter context, line, callback
        else
            hits = completions.filter (c) ->
                c.indexOf(line) is 0

        if line.length
            callback null, [hits, line]
        else
            callback null, [completions, line]
