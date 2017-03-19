###
Base class for reading Area files from different MUD formats. The base
class reads from a JSON file to serve as an example. Uses the event system.

Events: `area`, `room`

###
events = require 'events'
_ = require 'underscore'
fs = require 'fs'
path = require 'path'
async = require 'async'

class JSONReader extends events.EventEmitter
  # Check our fd to see if we can import and report our confidence (0-10)
  @canImport: (data) ->
    return 8 if data[0] is '{'
    0

  constructor: (@data) -> super()

  read: ->
    @log?.debug "AreaReader: #{@data}"
    areaFile = JSON.parse @data
    if not areaFile?
      return

    area =
      id: areaFile.id
      title: areaFile.title
      description: areaFile.description

    @emit 'area', area

    if areaFile.rooms?
      for id, room of areaFile.rooms
        room.id = id
        @emit 'room', room

    @emit 'done'

module.exports = (options, imports, register) ->
  {mud, log, world} = imports

  JSONReader::log = new log.Logger "JSONReader"

  class ImporterPlugin
    importers: {}
    constructor: ->
      @log = new log.Logger @constructor.name

    register: (importer) ->
      @importers[importer.name] = importer
      @log.info "Registered importer %s", importer.name
      mud.emit "importer:register", importer

    unregister: (importer) ->
      name = null
      if _.isString importer
        delete @importers[importer]
        name = importer
      else
        for k, v of @importers
          if v is importer
            name = v.name
            delete @importers[k]
            break

      @log.info "Unregistered importer %s", name
      mud.emit "importer:unregister", name

    getImporter: (data) ->
      data = data.toString()
      @log.debug "Finding importer for %j", data[..20]
      best = null
      maxScore = 0
      for k, v of @importers
        importer = @importers[k]
        score = importer.canImport data
        @log.debug "Importer %s has score of %d", importer.name, score
        if score > maxScore
          maxScore = score
          best = importer

      new best data if best?

  importerPlugin = new ImporterPlugin()
  importerPlugin.register JSONReader
  world.commands.loadDirectory path.join(__dirname, 'commands'),
    importer: importerPlugin
    model: imports.model

  register null,
    importer: importerPlugin
