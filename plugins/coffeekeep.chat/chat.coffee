_ = require 'underscore'
event = require 'event'

class Channel extends event.EventEmitter
  defaults:
    acl: "+all"       # Security mask
    distance: "world"     # [world|area|room|<# of rooms>]

  constructor: (@options)

module.exports = (options, imports, register) ->
  _(options).defaults
    channels:
      gossip:
        acl: "+all"
        distance: "world"
      archon:
        acl: "-all +sysop"
        distance: "world"
      ooc:
        acl: "+all"
        distance: "world"
