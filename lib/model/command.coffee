fs = require 'fs'
path = require 'path'
coffee = require 'coffee-script'
{splitFull} = require '../util'
{Model, Collection} = require './'

exports.Command = class Command extends Model
    idAttribute: 'name'
    defaults:
        name: 'lazy'                    # Primary command name
        aliases: []                     # Other command names
        prefixChar: null                # Get anything starting with char
        description: "I don't really do anything"
        help: "Usage: lazy. Dats it"

        action: (context, request) ->
            {mob} = context
            mob.print "The lazy command does nothing."

    toString: -> "[command #{@id}]"

    doCommand: (context, commandStr, callback) ->
        [verb, args...] = splitFull commandStr
        verb = verb.toLowerCase()
        request =
            verb: verb
            args: args
            line: commandStr
        action = @get('action')
        if action.length < 3
            action context, request
            do callback
        else
            action context, request, callback

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

    doCommand: (context, commandStr, callback) ->
        [verb, args...] = splitFull commandStr
        commandModel = @get verb
        if not commandModel?
            models = @filter (c) ->
                aliases = c.get 'aliases'
                if not aliases?
                    return false

                verb in aliases
            if models.length > 1
                console.error "WARNING: Multiple commands found for alias '#{verb}'"

            commandModel = models[0]

        if not commandModel?
            context.mob.print "I don't know how to #{verb}."
            return

        commandModel.doCommand context, commandStr, callback

    updateValidCommands: ->
        console.log "Updating valid commands"
        commands = @pluck 'name'
        aliases = []
        @forEach (command) ->
            commandAliases = command.get 'aliases'
            if commandAliases
                aliases = aliases.concat command.get 'aliases'

        @validCommands = commands.sort()
        @validAliases = aliases.sort()
        @validVerbs = commands.concat(aliases).sort()

    readlineCompleter: (line, callback) ->
        # TODO: chain completer to command
        completions = @validVerbs
        hits = completions.filter (c) ->
            c.indexOf(line) is 0

        if line.length
            callback null, [hits, line]
        else
            callback null, [completions, line]
