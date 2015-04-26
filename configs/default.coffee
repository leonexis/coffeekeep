path = require 'path'
module.exports = exports = [
    packagePath: './coffeekeep.core'
    host: process.env.IP ? '0.0.0.0'
    port: process.env.PORT ? 8080
  './coffeekeep.log'
  './coffeekeep.model'
    packagePath: './coffeekeep.interpreter'
    debug: true
  './coffeekeep.importer'
  './coffeekeep.importer.rom'
    packagePath: './coffeekeep.storage.sqlite'
    database: path.join __dirname, '..', 'coffeekeep.sqlite'
  ,
    packagePath: './coffeekeep.messaging'
    channels:
      gossip:
        format: '{Name} gossip{s}, "{text}"'
      ooc:
        format: '{Name} OOC{s}, "{text}"'
      achat:
        format: '{Name} achat{s}, "{text}"'
      newbie:
        format: '{Name} newbie{s}, "{text}"'

]
