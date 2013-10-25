{EventEmitter} = require 'events'
{Command, CommandCollection} = require './command.coffee'

class InterpreterPlugin extends EventEmitter
    constructor: (@options, @imports) ->
        @imports.model.register "command", Command, CommandCollection
        @commands = new CommandCollection imports.world

module.exports = (options, imports, register) ->

    interpreterPlugin = new InterpreterPlugin options, imports
    register null,
        interpreter: interpreterPlugin
        commands: interpreterPlugin.commands