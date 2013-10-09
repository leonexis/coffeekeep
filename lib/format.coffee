_ = require 'underscore'

exports.CSI = CSI = '\x1b'

exports.ANSI_COLOR = ANSI_COLOR =
    black: 0
    red: 1
    green: 2
    yellow: 3
    blue: 4
    magenta: 5
    cyan: 6
    white: 7

exports.ANSI_SGR = ANSI_SGR =
    reset: 0                        # Reset all SGR attributes
    bold: 1
    negative: 7                     # Reverse background and foreground
    normal: 22                      # Undo bold?
    positive: 27                    # Undo negative?
    setColorForeground: 30          # + ANSI_COLOR
    setXterm256Foreground: 38       # CSI + [38;2;x;x;xm
    setColorBackground: 40          # + ANSI_COLOR
    setXterm256Background: 48       # see foreground

fg = (color) -> CSI + '[' + (ANSI_SGR['setColorForeground'] + ANSI_COLOR[color]).toString() + 'm'
bg = (color) -> CSI + '[' + (ANSI_SGR['setColorBackground'] + ANSI_COLOR[color]).toString() + 'm'

ansiExp = (fn) -> (next) ->
    if next?
        parts = next[2...-1].split ';'
    else
        parts = []
    parts.unshift fn
    CSI + '[' + parts.join(';') + 'm'

reset = ansiExp ANSI_SGR['reset']
bold = ansiExp ANSI_SGR['bold']
negative = ansiExp ANSI_SGR['negative']
normal = ansiExp ANSI_SGR['normal']
positive = ansiExp ANSI_SGR['positive']
themed = (key) ->
    {_theme: key}


exports.defaultTheme = defaultTheme =
    normal: do reset
    roomTitle: bold fg 'cyan'
    roomDescription: do reset
    roomExtra: bold fg 'cyan'
    roomExtraSeen: fg 'cyan'
    direction: fg 'yellow'
    unexploredDirection: bold fg 'yellow'
    door: fg 'cyan'
    unexploredDoor: bold fg 'cyan'
    emote: fg 'yellow'
    fight: fg 'red'
    spell: bold fg 'blue'
    talk: bold fg 'green'
    yell: bold fg 'red'
    weather: bold fg 'cyan'
    mob: fg 'magenta'
    item: fg 'yellow'
    system: fg 'magenta'

# All format codes preceded by %.
exports.FORMAT_CODES = FORMAT_CODES =
    '%': '%'
    'N': themed 'normal'
    '.': do reset
    '!': do bold
    'H': do negative
    'k': fg 'black'
    'r': fg 'red'
    'g': fg 'green'
    'y': fg 'yellow'
    'b': fg 'blue'
    'p': fg 'magenta'
    'c': fg 'cyan'
    'w': fg 'white'
    'K': bold fg 'black'
    'R': bold fg 'red'
    'G': bold fg 'green'
    'Y': bold fg 'yellow'
    'B': bold fg 'blue'
    'P': bold fg 'magenta'
    'C': bold fg 'cyan'
    'w': bold fg 'white'
    'e': themed 'emote'
    'f': themed 'fight'
    's': themed 'spell'
    't': themed 'talk'
    'l': themed 'yell'
    'h': themed 'weather'
    'T': themed 'roomTitle'
    'L': themed 'roomDescription'
    'x': themed 'roomExtra'
    'X': themed 'roomExtraSeen'
    'o': themed 'direction'
    'O': themed 'unexploredDirection'
    'd': themed 'door'
    'D': themed 'unexploredDoor'
    'S': themed 'system'
    'm': themed 'mob'

exports.format = format = (text, theme, color=true) ->
    theme ?= defaultTheme
    out = ""
    index = 0
    while index < text.length
        char = text[index++]
        if char is '%'
            code = text[index++]
            fcode = FORMAT_CODES[code]
            if fcode?
                if fcode._theme?
                    fcode = theme[fcode._theme]
                    if not fcode?
                        fcode = char + code
                out += fcode if color
            else
                out += char + code
        else
            out += char
    out

exports.unformat = unformat = (text) ->
    ###
    Converts a string with command codes in to a raw string without them
    ###
    text.replace /\x1b\[[\d:;]+[a-zA-Z]/g, ''


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
    ###

    @termsByGender:
        he: ['it', 'he', 'she', 'zhe', 'you']
        his: ['its', 'his', 'her', 'zher', 'your']
        him: ['it', 'him', 'her', 'zher', 'you']
        himself: ['itself', 'himself', 'herself', 'zherself', 'yourself']
        hisself: ['itself', 'hisself', 'herself', 'zherself', 'yourself']

    constructor: ({@message, @type, @observer, @subject, @target}) ->
        @tokens = @parse @message
        @_tokensCache = @message

    token: (token) ->
        isFirstCap = token[0] isnt token[0].toLowerCase()
        token = token.toLowerCase()

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

    forObserver: (observer) ->
        oldObserver = @observer
        @observer = observer
        if @_tokenCache isnt @message
            @tokens = @parse @message
            @_tokensCache = @message

        out = ""
        for token in @tokens
            if token.token?
                out += @token token.data
            else
                out += token

        @observer = oldObserver
        out

    toString: -> @forObserver @observer

exports.Message = Message