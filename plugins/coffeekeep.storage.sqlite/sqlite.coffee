###
Augment a Backbone Model to use sqlite as the backend storage
###
path = require 'path'
sqlite3 = require 'sqlite3'
util = require 'util'
_ = require 'underscore'

class StorageError extends Error
  # For instanceof to work, the following is required whenever subclassing
  # TODO: Check if this is still the case with CS2/ES6
  constructor: -> super()

class NotFoundError extends StorageError
  constructor: -> super()

class ExistsError extends StorageError
  constructor: -> super()

getSync = (_log, db) -> (method, model, options) ->
  options ?= {}
  log = new _log.Logger 'coffeekeep.storage.sqlite'

  url = _.result model, 'url'

  log.silly "sync: %s: %s, %j, %j", url, method, model, options

  if not url?
    throw new Error "Could not get url for this model #{util.inspect model}"

  switch method
    when 'create'
      obj = JSON.stringify model.attributes
      db.run "INSERT INTO objects VALUES (?, ?)", url, obj, (err) ->
        if err?
          log.error "Error while creating", err
          if err.code == 'SQLITE_CONSTRAINT'
            return options.error? new ExistsError err
          return options.error? err
        options.success? null

    when 'update'
      obj = JSON.stringify model.attributes
      db.run "UPDATE objects SET json = ? WHERE url = ?", obj, url, (err) ->
        if err?
          log.error "Error while updating %s: %s, %j, %j", url, method, model,
            options, err
          return options.error? err

        # Callback 'this' is the statement object
        if @changes == 0
          # Originally this created the object, but that was wrong
          log.error "Tried to update an non-existant object at %s", url
          return options.error? new NotFoundError "Cannot update non-existant
            object at #{url}"
        else
          options.success? null

    when 'read'
      if url[url.length - 1] is '/'
        # This is a container
        db.all "SELECT url, json FROM objects WHERE url LIKE ? AND url NOT
          LIKE ?", url + "%", url + "%/%",
          (err, rows) ->
            if err?
              log.error "Error while reading multiple %s: %s, %j, %j", url,
                method, model, options, err
              return options.error? err
            out = []
            for row in rows
              out.push JSON.parse row.json
            options.success? out
      else
        # Read a single object
        db.get "SELECT url, json FROM objects WHERE url = ?", url, (err, row) ->
          if err?
            log.error "Error while reading single %s: %s, %j, %j", url, method,
              model, options, err
            return options.error? err

          if not row?
            return options.error? new NotFoundError "Object not found"

          options.success JSON.parse row.json

    when 'delete'
      db.run "DELETE FROM objects WHERE url = ?", url, (err) ->
        if err?
          log.error "Error during delete: #{util.inspect [model, options, err]}"
          return options.error? err
        options.success? null

  model.trigger 'request', model, null, options
  null

module.exports = (options, imports, register) ->
  console.assert options.database?, "Must specify database"
  _.defaults options,
    verbose: false

  if options.verbose
    sqlite3.verbose()

  db = new sqlite3.Database options.database
  db.serialize ->
    db.run "CREATE TABLE IF NOT EXISTS objects (url PRIMARY KEY, json)"

  register null,
    storage:
      StorageError: StorageError
      NotFoundError: NotFoundError
      ExistsError: ExistsError
      sync: getSync imports.log, db
