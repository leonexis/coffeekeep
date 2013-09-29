readers = require './'
fs = require 'fs'

exports.ROMReader = class ROMReader extends readers.AreaReader
    debug: false
    
    ROM_DIRECTIONS: ['north', 'east', 'south', 'west', 'up', 'down']
    
    getString: ->
        # Get string up to ~
        data = @getLine()
        while data? and data.indexOf("~") == -1
            data += '\n' + @getLine()
        data = data.split('~')[0]
        console.log "Got string #{data}" if @debug
        data
    
    getLine: ->
        [@line, @lines...] = @lines
        @lineIndex += 1
        #console.log "Parsing line #{@lineIndex}/#{@linesTotal}: #{@line}" if @debug
        if not @line?
            throw new Error "End of file"
        @line
        
    getList: ->
        @getLine().split(' ')
    
    strToList: (text) ->
        `text = text.replace(/\s{2,}/g, ' ')`
        text.split ' '
    
    read: (filename) ->
        data = fs.readFileSync filename, encoding: 'ascii'
        state = null
        current = null
        index = 0
        @lineIndex = 0
        @lines = data.split '\n'
        @linesTotal = @lines.length
        while @lines.length > 0
            @getLine()
            if not @line or @line.indexOf("#") != 0
                # Eat everything up until the next section
                continue
            
            console.log "Found marker #{@line}" if @debug
            index = Number @line[1..]
            
            if not index? or Number.isNaN index
                state = @line[1..].toLowerCase()
                console.log "Marker is a new section #{state} (#{@line})" if @debug
                if state in ['mobiles', 'rooms', 'objects']
                    # These require restarting to find new index
                    continue
            else
                console.log "Marker is new index #{index}" if @debug
                if index == 0
                    console.log "End of section found, skipping" if @debug
                    continue
            
            switch state
                when 'area'
                    current = {}
                    current.id = @getString()
                    current.description = @getString()
                    
                    title = @getString()
                    if title? and title.indexOf '{' is 0 and title.indexOf '}' > 0
                        [levels, title] = title.split('}')
                        levels = levels[1..].trim()
                        [current.minLevel, current.maxLevel] = @strToList levels
                    current.title = title
                    
                    @getList() # Lower and upper bounds of index, not needed
                
                when 'rooms'
                    current = {}
                    current.id = do index.toString
                    current.title = @getString()
                    current.description = @getString()
                    [current.x_obsolete_area, current.x_roomFlags, current.x_sectorType] = @getList()
                    current.links = {}
                    current.extras = []
                    while (subsec = @getLine()) and subsec != 'S'
                        # FIXME: Not getting exits
                        switch subsec[0]
                            when 'D'
                                link = {}
                                direction = @ROM_DIRECTIONS[Number(subsec[1..])]
                                link.description = @getString()
                                link.keywords = @getString()
                                [link.x_locks, link.x_key, link.room] = @getList()
                                current.links[direction] = link
                            when 'E'
                                extra = {}
                                extra.keywords = @getString()
                                extra.description = @getString()
                                current.extras.push(extra)
                            
                        
            
            if state? and current?
                emitState = switch state
                    when 'rooms' then 'room'
                    else state
                console.log "Emitting #{emitState}, #{JSON.stringify current}" if @debug
                @emit emitState, current
                
            current = null
        
        @emit 'done'

exports.ROMReader = ROMReader