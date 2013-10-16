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
        @index = 0
        @lineIndex = 0
        @lines = data.split '\n'
        @linesTotal = @lines.length
        while @lines.length > 0
            @getLine()
            if not @line or @line.indexOf("#") != 0
                # Eat everything up until the next section
                continue

            console.log "Found marker #{@line}" if @debug
            @index = Number @line[1..]

            if not @index? or Number.isNaN @index
                state = @line[1..].toLowerCase()
                console.log "Marker is a new section #{state} (#{@line})" if @debug
                if state in ['mobiles', 'rooms', 'objects']
                    # These require restarting to find new index
                    continue
            else
                console.log "Marker is new index #{@index}" if @debug
                if @index == 0
                    console.log "End of section found, skipping" if @debug
                    continue

            switch state
                when 'area'
                    current = @getArea()
                when 'rooms'
                    current = @getRoom()
                when 'mobiles'
                    current = @getMobile()
                when 'objects'
                    current = @getObject()

            if state? and current?
                emitState = switch state
                    when 'rooms' then 'room'
                    when 'mobiles' then 'mobile'
                    when 'objects' then 'item'
                    else state
                console.log "Emitting #{emitState}, #{JSON.stringify current}" if @debug
                @emit emitState, current

            current = null

        @emit 'done'

    getArea: ->
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

        current

    getRoom: ->
        current = {}
        current.id = @index.toString()
        current.title = @getString()
        current.description = @getString()
        [current.x_rom_obsolete_area,
         current.x_rom_roomFlags,
         current.x_rom_sectorType] = @getList()
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
                    [isDoor, link.x_rom_key, link.room] = @getList()
                    # TODO support locks
                    link.door = isDoor > 0
                    current.links[direction] = link
                when 'E'
                    extra = {}
                    extra.keywords = @getString()
                    extra.description = @getString()
                    current.extras.push(extra)

        current

    getMobile: ->
        current =
            id: @index.toString()
            name: @getString()              # wizard
            shortDescription: @getString()  # the wizard
            longDescription: @getString()   # A wizard walks around in deep thought.
            extraDescription: @getString()  # The pale wizard looks ...
            x_rom_race: @getString()        # human

        [current.x_rom_actionFlags,
         current.x_rom_affectedFlags,
         current.x_rom_alignment,
         current.x_rom_group] = @getList()

        [current.level,
         current.x_rom_hitroll,
         current.x_rom_hitDice,
         current.x_rom_manaDice,
         current.x_rom_damageDice,
         current.x_rom_damageType] = @getList()

        [current.x_rom_offFlags,
         current.x_rom_immFlags,
         current.x_rom_resFlags,
         current.x_rom_vulnFlags] = @getList()

        [current.x_rom_startPosition,
         current.x_rom_defaultPosition,
         current.x_rom_sex,
         current.x_rom_wealth] = @getList()

        [current.x_rom_form,
         current.x_rom_parts,
         current.x_rom_size,
         current.x_rom_material] = @getList()

    getObject: ->
        current =
            id: @index.toString()
            name: @getString()
            shortDescription: @getString()
            description: @getString()
            x_rom_material: @getString()

        [current.x_rom_itemType,
         current.x_rom_extraFlags,
         current.x_rom_wearFlags] = @getList()

        current.x_rom_value = @getList()

        [current.level,
         current.weight,
         current.x_rom_cost,
         current.x_rom_condition] = @getList()

        current.extras = []
        current.x_rom_affected = []
        while (subsec = @getLine())
            switch subsec[0]
                when '#'
                    @lines.unshift subsec
                    return current

                when 'A'
                    [loc, mod] = @getList()
                    current.x_rom_affected.push
                        type: -1
                        level: current.level
                        duration: -1
                        location: loc
                        modifier: mod
                        bitvector: 0

                when 'F'
                    [where, loc, mod, vector] = @getList()
                    current.x_rom_affected.push
                        type: -1
                        level: current.level
                        duration: -1
                        location: loc
                        modifier: mod
                        bitvector: vector
                        where: where

                when 'E'
                    current.extras.push
                        keywords: @getString()
                        description: @getString()

        current





exports.ROMReader = ROMReader