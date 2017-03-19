###
Augment a Backbone Model to use an in-memory key-value store
(mainly for testing)
###
util = require 'util'
_ = require 'underscore'
debug = require('debug') 'coffeekeep.storage.memory'

class StorageError extends Error
  # For instanceof to work, the following is required whenever subclassing
  # TODO: Check if this is still the case with CS2/ES6
  constructor: -> super()

class NotFoundError extends StorageError
  constructor: -> super()

class ExistsError extends StorageError
  constructor: -> super()

class SyncHistory
  constructor: (@maxLength) ->
    @history = []

  add: (obj) ->
    @history.push obj
    @history.shift() while @history.length > @maxLength
    @length = @history.length

  get: (index) ->
    # Index should be a negative number..
    if index < 0
      index += @history.length

    @history[index]

  getLast: -> @get -1

getSync = (log, db, history) -> (method, model, options) ->
  options ?= {}

  url = _.result model, 'url'

  log.silly "coffeekeep.storage.memory",
    "sync: %s: %s, %j, %j", url, method, model, options

  debug "sync: %s: %s, %j, %j", url, method, model, options

  history.add
    url: url
    method: method
    model: model? and JSON.stringify model.attributes
    options: options

  if not url?
    throw new Error "Could not get url for this model #{util.inspect model}"

  switch method
    when 'create'
      if db[url]?
        process.nextTick ->
          options.error? new ExistsError "Object at #{url} already exists"
        return

      obj = JSON.stringify model.attributes
      db[url] = obj
      process.nextTick ->
        options.success? null

    when 'update'
      unless db[url]?
        process.nextTick ->
          options.error? new NotFoundError "Cannot update non-existant object
            at #{url}"
        return

      obj = JSON.stringify model.attributes
      db[url] = obj
      process.nextTick ->
        options.success? null

    when 'read'
      if url[url.length - 1] is '/'
        # This is a container
        out = _.chain db
          .keys()
          .filter (key) -> key.indexOf(url) == 0
          .filter (key) -> key[url.length..].indexOf('/') == -1
          .map (key) -> JSON.parse db[key]
          .value()

        process.nextTick -> options.success? out

      else
        # Read a single object
        out = db[url]
        debug "read object: %j", out
        if _.isUndefined out
          debug "_.isUndefined"
          return process.nextTick ->
            debug "send exception to %s", options.error
            options.error? new NotFoundError "Object not found"
        else
          out = JSON.parse out

        process.nextTick -> options.success? out

    when 'delete'
      if db[url]?
        delete db[url]

      process.nextTick -> options.success? null

  model.trigger 'request', model, null, options
  null


module.exports = (options, imports, register) ->
  _.defaults options,
    verbose: false

  db = {}
  history = new SyncHistory 100

  register null,
    storage:
      StorageError: StorageError
      NotFoundError: NotFoundError
      ExistsError: ExistsError
      sync: getSync imports.log, db, history
      _db: db
      _history: history
      _reset: -> _.chain(db).keys().map((key) -> delete db[key])
