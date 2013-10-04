
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
    direction: bold fg 'yellow'
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

