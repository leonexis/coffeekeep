readline = require 'readline'

rl = readline.createInterface
    input: process.stdin
    output: process.stdout
    
rl.on 'line', (line) ->
    if not line?
        return
    if line.length == 0
        return
    parts = line.split ' '
    if parts.length == 1
        cmd = parts[0]
        args = []
    else
        cmd = parts[0]
        args = parts[1..]
    rl.write "You said #{cmd} with args #{args}"