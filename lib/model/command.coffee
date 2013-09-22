fs = require 'fs'
path = require 'path'
{splitFull} = require '../util'
{Model, Collection} = require './'

exports.Command = class Command extends Model
    idAttribute: 'name'
    defaults:
        name: 'lazy'                    # Primary command name
        aliases: ['nop']                # Other command names
        prefixChar: null                # Get anything starting with char
        description: "I don't really do anything"
        help: "Usage: lazy. Dats it"
        
        action: (context, request) ->
            {mob} = context
            mob.print "The lazy command does nothing."
    
    doCommand: (context, commandStr, cb) ->
        [verb, args...] = splitFull commandStr
        verb = verb.toLowerCase()
        request =
            verb: verb
            args: args
            line: commandStr
        @get('action') context, request
    
exports.CommandCollection = class CommandCollection extends Collection
    loadDirectory: (dirName) ->
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
    
    loadFile: (fileName, reload=false) ->
        # Load a command file that exports `exports.commands`
        try
            base = fileName[...fileName.lastIndexOf '.']
            if reload and require.cache[base]?
                delete require.cache[base]
                
            {commands, command} = require base
            if not commands?
                if command?
                    commands = [command]
                else
                    console.error "WARNING: Could not load #{base}"
                    return false
            for command in commands
                unless command instanceof Command
                    command = new Command command
                
                oldCommand = @get command.get 'name'
                if oldCommand?
                    if reload
                        console.log "Reloaded command '#{command.get 'name'}'"
                    else
                        console.error "WARNING: Command '#{command.get 'name'}' already
 exists from #{oldCommand.get 'fileName'}. Replacing."
                    oldCommand.set command.attributes
                    return true
                    
                command.set 'fileName': fileName
                @add command
                console.log "Loaded command '#{command.get 'name'}'"
            return true
        catch error
            console.error "Error while loading commands from #{base}: #{error.toString()}"
            console.error error.stack
            return false
    
    doCommand: (context, commandStr) ->
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
        
        commandModel.doCommand context, commandStr