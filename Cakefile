fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

build = (src, dst, callback) ->
  coffee = spawn 'coffee', ['-c', '-m', '-o', dst, src]
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

docs = (callback) ->
  coffeedoc = spawn 'node_modules/.bin/coffeedoc', ['lib']
  coffeedoc.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffeedoc.stdout.on 'data', (data) ->
    print data.toString()
  coffeedoc.on 'exit', (code) ->
    callback?() if code is 0

tests = (callback) ->
  mocha = spawn 'node_modules/.bin/mocha', [
    '--compilers', 'coffee:coffee-script',
    '--reporter', 'spec',
    '--recursive', '-c'
    'test']
  mocha.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  mocha.stdout.on 'data', (data) ->
    print data.toString()
  mocha.on 'exit', (code) ->
    callback?() if code is 0

task 'build', 'Build build/plugins/ from plugins/', ->
  build 'plugins/', 'build/plugins/', ->
    build 'test/', 'build/test/'

task 'docs', 'Build documentation in docs/', ->
  docs()

task 'watch', 'Watch for changes', ->
  coffee = spawn 'coffee', ['-w', '-c', '-m', '-o', 'build/plugins', 'plugins']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()

task 'test', 'Run tests', ->
  tests()
