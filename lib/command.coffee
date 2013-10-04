exports.run = ->
    engine = require './engine'
    do engine.startMud

if not module.parent?
    exports.run()