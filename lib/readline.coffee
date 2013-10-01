###
# Readline Extensions #
Extends Node.JS's internal readline library to allow for disabling local
echos for entering passwords or other screts.

## Usage ##
Use like you would the original readline library.

## Enable and Disable Echo ##
Use the following form when asking for a password:

    # rl = new readline.Interface ...
    rl.setEcho off
    rl.question "Enter a password: ", (password) ->
        rl.setEcho on
        console.log "Entered password #{password}"

## History ##
If the echo mode is not `ECHO_NORMAL`, input is prevented from being added
to the history for security purposes
        
###
readline = require 'readline'
format = require './format'

exports.ECHO_NORMAL = ECHO_NORMAL = 0
exports.ECHO_SECRET = ECHO_SECRET = 1
exports.ECHO_CENSOR = ECHO_CENSOR = 2

exports.Interface = class Interface extends readline.Interface
    # Extend Node.JS Readline interface
    constructor: (options) ->
        @echoMode = ECHO_NORMAL
        super options
    
    setEcho: (setting) ->
        ###
        Set the echo mode.
        
        `setting` can be one of:
        
         - `'normal'` - Enables normal mode
         - `'secret'` - Do not echo anything
         - `'censor'` - Echo '*' for each character entered
        
        
        ###
        @echoMode = switch setting
            when 'normal', true, ECHO_NORMAL then ECHO_NORMAL
            when 'secret', false, ECHO_SECRET then ECHO_SECRET
            when 'censor', ECHO_CENSOR then ECHO_CENSOR
            else ECHO_NORMAL
    
    _refreshLine: ->
        return super if @echoMode is ECHO_NORMAL
        line = @line
        cursor = @cursor
        switch @echoMode
            when ECHO_SECRET
                @line = ''
                @cursor = 0
            when ECHO_CENSOR
                @line = @line.replace /[\s\S]/g, '*'
        super
        @line = line
        @cursor = cursor
    
    _insertString: (c) ->
        return super c if @echoMode is ECHO_NORMAL
        
        # Adapted from Node.JS's readline to always refresh with @_refreshLine
        if @cursor < @line.length
            beg = @line[...@cursor]
            end = @line[@cursor..]
            @line = beg + c + end
            @cursor += c.length
        else
            @line += c
            @cursor += c.length
        
        if @echoMode isnt ECHO_SECRET
            # dont bother refreshing if we aren't going to change anything
            do @_refreshLine
    
    _tabComplete: -> super if @echoMode is ECHO_NORMAL
    
    _addHistory: -> 
        return super if @echoMode is ECHO_NORMAL
        @line
    
    setPrompt: (prompt) ->
        # This is fixed in a development version of Node, but for v0.10....
        # Adapted from readline.js from https://github.com/joyent/node
        cleanPrompt = format.unformat prompt
        super prompt, cleanPrompt.length
    