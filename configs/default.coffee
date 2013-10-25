path = require 'path'
module.exports = exports = [
        packagePath: './coffeekeep.core'
        host: process.env.IP ? '0.0.0.0'
        port: process.env.PORT ? 8080
    './coffeekeep.log'
    './coffeekeep.model'
    './coffeekeep.interpreter'
    './coffeekeep.importer'
    './coffeekeep.importer.rom'
        packagePath: './coffeekeep.storage.sqlite'
        database: path.join __dirname, '..', 'coffeekeep.sqlite'
]