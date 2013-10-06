should = require 'should'
security = require '../lib/security'

describe 'security', ->
    describe 'AttributeResolver', ->
        br = new security.AttributeResolver
            foo: 1
            bar: 'baz'
            tree:
                leaf: 'foo'
            list: ['foo', 'bar']

        it 'should support "get"', ->
            br.get('foo').should.eql 1
            br.get('bar').should.eql 'baz'

        it 'should support dotted property form', ->
            br.get('tree.leaf').should.eql 'foo'
            should(br.get('tree.foo')).eql null
            should(br.get('trees.baz')).eql null

        it 'should support "equal"', ->
            br.equal('bar', 'baz').should.be.true
            br.equal('bar', 'faz').should.be.false
            br.equal('foo', 1).should.be.true
            br.equal('foo', '1').should.be.true

        it 'should support "gt"', ->
            br.gt('foo', 0).should.be.true
            br.gt('foo', 1).should.be.false
            br.gt('foo', 2).should.be.false
            br.gt('bar', 0).should.be.false

        it 'should support "gte"', ->
            br.gte('foo', 0).should.be.true
            br.gte('foo', 1).should.be.true
            br.gte('foo', 2).should.be.false
            br.gte('bar', 0).should.be.false

        it 'should support "lt"', ->
            br.lt('foo', 0).should.be.false
            br.lt('foo', 1).should.be.false
            br.lt('foo', 2).should.be.true
            br.lt('bar', 0).should.be.false

        it 'should support "lte"', ->
            br.lte('foo', 0).should.be.false
            br.lte('foo', 1).should.be.true
            br.lte('foo', 2).should.be.true
            br.lte('bar', 0).should.be.false

        it 'should support "has"', ->
            br.has('list', 'foo').should.be.true
            br.has('list', 'baz').should.be.false

        it.skip 'should support substrings in "has"', ->
            br.has('bar', 'oo').should.be.false
            br.has('bar', 'az').should.be.true

    describe 'MaskFactory', ->
        describe '#parse', ->
            mf = new security.MaskFactory()

            it 'should parse just attributes', ->
                tokens = mf.parse 'all'
                tokens.should.have.length 1
                tokens[0].should.have.property 'name', 'all'
                tokens[0].should.not.have.property 'operator'
                tokens[0].should.not.have.property 'value'

            it 'should parse complex attributes', ->
                tokens = mf.parse 'level>5'
                tokens.should.have.length 1
                tokens[0].should.have.property 'name', 'level'
                tokens[0].should.have.property 'operator', '>'
                tokens[0].should.have.property 'value', '5'

            it 'should only allow <, > with numbers', ->
                for op in ['>', '<', '>=', '<=']
                    do ->
                        (->
                            mf.parse "level#{op}foo"
                        ).should.throw /does not match/
                        (->
                            mf.parse "level#{op}5"
                        ).should.not.throw()

            it 'should support floating point numbers for <, >', ->
                mf.parse "level<0.52342"
                mf.parse "level>1.31234:foo"
                mf.parse "level<=4.22134:foo,bar"
                tokens = mf.parse "level>=0.999:foo,baz"
                tokens.should.have.length 1
                tokens[0].should.have.property 'name', 'level'
                tokens[0].should.have.property 'operator', '>='
                tokens[0].should.have.property 'value', '0.999'

            it 'should support prefixes +, - or no prefix', ->
                for op in ['+', '-']
                    do ->
                        token = mf.parse op + "all"
                        token[0].should.have.property 'prefix', op

            it 'should support multiple permissions', ->
                tokens = mf.parse 'level:one,two'
                tokens.should.have.length 1
                tokens[0].should.have.property 'permissions'
                tokens[0].permissions.should.have.length 2
                tokens[0].permissions[0].should.eql 'one'

            it 'should support quotes with spaces', ->
                tokens = mf.parse 'name="foo bar"'
                tokens.should.have.length 1
                tokens[0].should.have.property 'name', 'name'
                tokens[0].should.have.property 'operator', '='
                tokens[0].should.have.property 'value', 'foo bar'

            it 'should support multiple tokens in an ACL', ->
                tokens = mf.parse '+all:say,tell +level>5:ooc -guest:ooc'
                tokens.should.have.length 3
                [t0, t1, t2] = tokens
                t0.should.have.property 'name', 'all'
                t0.should.have.property 'prefix', '+'
                t1.should.have.property 'name', 'level'
                t1.should.have.property 'operator', '>'
                t1.permissions.should.have.length 1
                t1.permissions.should.eql ['ooc']
                t2.should.have.property 'prefix', '-'

        describe '#resolve', ->
            fr = null
            mf = new security.MaskFactory()

            beforeEach ->
                fr = new security.AttributeResolver
                    sysop: false
                    abilities:
                        foo: 3
                    level: 5

            it 'should resolve "all"', ->
                perms = mf.resolve '+all:one', fr
                perms.should.include ''
                perms.should.include 'one'

            it 'should support additive tokens', ->
                perms = mf.resolve '+all +level>6:one +abilities.foo:two', fr
                perms.should.include ''
                perms.should.include 'two'
                perms.should.not.include 'one'

            it 'should support subtractive tokens', ->
                perms = mf.resolve(
                    '+all:one,two,three -level<5:two -level<10:three', fr)
                perms.should.include ''
                perms.should.include 'one'
                perms.should.include 'two'
                perms.should.not.include 'three'

    describe 'Mask', ->
        ar = null
        beforeEach ->
            ar = new security.AttributeResolver
                    sysop: false
                    abilities:
                        foo: 3
                    level: 5

        it 'should resolve', ->
            mask = new security.Mask '+all:one'
            mask.resolve(ar).should.include 'one'

        it 'should check for permissions', ->
            mask = new security.Mask '+all:one'
            mask.hasPermission(ar, 'one').should.be.true

        it 'should allow positive wildcards', ->
            mask = new security.Mask '-all +level>5 +sysop:*'
            mask.hasPermission(ar, 'anything').should.be.false
            mask.hasPermission(ar, '').should.be.false
            ar.attributes['level'] = 6
            mask.hasPermission(ar, '').should.be.true
            mask.hasPermission(ar, 'anything').should.be.false
            ar.attributes['level'] = 5
            ar.attributes['sysop'] = true
            mask.hasPermission(ar, '').should.be.true
            mask.hasPermission(ar, 'anything').should.be.true

    describe 'Mob#hasPermission', ->
        it 'should match on basic attributes'
        it 'should match on gender string'

