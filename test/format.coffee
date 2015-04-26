should = require 'should'
format = require '../lib/format'
{Mob} = require '../lib/model/mob'

describe 'format', ->
  class FakeMob
    constructor: (opts={}) ->
      for k, v of opts
        @[k] = v
    get: (key) -> @[key]

  describe 'Message', ->
    mob1 = mob2 = mob3 = mob4 = msg = null

    beforeEach ->
      mob1 = new FakeMob
        gender: 0
        name: 'foo'

      mob2 = new FakeMob
        gender: 1
        name: 'bar'

      mob3 = new FakeMob
        gender: 2
        name: 'baz'

      mob4 = new FakeMob
        gender: 3
        name: 'faz'

      msg = new format.Message
        message: ''
        observer: mob3
        subject: mob1
        target: mob2

    describe '#token', ->
      it 'should support he/she/it', ->
        msg.token('he').should.eql 'it'
        msg.subject.gender = 1
        msg.token('he').should.eql 'he'
        msg.subject.gender = 2
        msg.token('he').should.eql 'she'
        msg.subject.gender = 3
        msg.token('he').should.eql 'zhe'
        msg.subject = msg.observer
        msg.token('he').should.eql 'you'

      it 'should support him/her/it', ->
        msg.token('him').should.eql 'it'
        msg.subject.gender = 1
        msg.token('him').should.eql 'him'
        msg.subject = msg.observer
        msg.token('him').should.eql 'you'

      it 'should capitalize the first letter if needed', ->
        msg.token('He').should.eql 'It'

      it 'should detect ^ as target', ->
        msg.token('^he').should.eql 'he'
        msg.token('^name').should.eql 'bar'

      it 'should support is/are', ->
        msg.token('he').should.eql 'it'
        msg.token('is').should.eql 'is'
        msg.observer = msg.subject
        msg.token('he').should.eql 'you'
        msg.token('is').should.eql 'are'

      it 'should support has/have', ->
        msg.token('he').should.eql 'it'
        msg.token('has').should.eql 'has'
        msg.observer = msg.subject
        msg.token('he').should.eql 'you'
        msg.token('has').should.eql 'have'

      it 'should support s/es endings', ->
        msg.token('he').should.eql 'it'
        msg.token('s').should.eql 's'
        msg.token('es').should.eql 'es'
        msg.observer = msg.subject
        msg.token('he').should.eql 'you'
        msg.token('s').should.eql ''
        msg.token('es').should.eql ''

      it 'should support name', ->
        msg.token('name').should.eql 'foo'
        msg.observer = msg.subject
        msg.token('name').should.eql 'you'

      it "should support name's", ->
        msg.token("name's").should.eql "foo's"
        msg.observer = msg.subject
        msg.token("name's").should.eql 'your'

      it 'should support nameself', ->
        msg.token('nameself').should.eql 'foo'
        msg.observer = msg.subject
        msg.token('nameself').should.eql 'yourself'

      it 'should support himself, herself, itself, yourself', ->
        msg.token('himself').should.eql 'itself'
        msg.subject.gender = 1
        msg.token('himself').should.eql 'himself'
        msg.observer = msg.subject
        msg.token('himself').should.eql 'yourself'

      it 'should support hisself, herself, itself, yourself', ->
        msg.token('hisself').should.eql 'itself'
        msg.subject.gender = 1
        msg.token('hisself').should.eql 'hisself'
        msg.observer = msg.subject
        msg.token('hisself').should.eql 'yourself'

    describe '#parse', ->
      it 'should parse without format tokens', ->
        msg.parse('foobar').should.eql ['foobar']

      it 'should pass on non-terminated format tokens', ->
        msg.parse('foo{bar').should.eql ['foo{bar']

      it 'should parse format tokens', ->
        msg.parse('foo{bar}').should.eql ['foo', {token: '{', data: 'bar'}]
        msg.parse('foo{bar} {baz} ').should.eql [
          'foo', {token: '{', data: 'bar'}, ' ',
          {token: '{', data: 'baz'}, ' ']
        msg.parse("{Name} hit{s} {^name}, killing {^him} while {he} defend{s}
          {himself}.").should.eql [
          {token:'{', data:'Name'}, ' hit',
          {token:'{', data:'s'}, ' ',
          {token:'{', data:'^name'}, ', killing ',
          {token:'{', data:'^him'}, ' while ',
          {token:'{', data:'he'}, ' defend',
          {token:'{', data:'s'}, ' ',
          {token:'{', data: 'himself'}, '.']

    describe '#forObserver', ->
      it 'should support specified observer', ->
        msg.message = "{Name} hit{s} {^name}, killing {^him} while {he}
          defend{s} {himself}."
        msg.forObserver(msg.observer).should.eql(
          'Foo hits bar, killing him while it defends itself.')
        msg.forObserver(msg.subject).should.eql(
          'You hit bar, killing him while you defend yourself.')
        msg.forObserver(msg.target).should.eql(
          'Foo hits you, killing you while it defends itself.')

    describe '#toString', ->
      it 'should use the default observer', ->
        msg.message = "{Name} hit{s} {^name}"
        msg.toString().should.eql 'Foo hits bar'
