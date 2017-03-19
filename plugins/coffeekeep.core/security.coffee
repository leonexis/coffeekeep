_ = require 'lodash'

###
Provide security related functions for permissions checking, etc

## Security Checks
Similar to MoinMoin ACL style

For the command look:
Anyone can look at the room, exits, items, and other mobs. Immortals can see
extended information such as IDs, etc. Sysops can see anything.

```CoffeeScript
# ACL: +all:room,exit,item,mob +immortal:extended +sysop:*
# Can even use/see the command:
@hasPermission mob
# If the user can look at the room:
@hasPermission mob, 'room'
# While showing the room, can see extended information
@hasPermission mob, 'extended'
# Very special information (or another as-of-yet unspecified command in ACL)
# Only sysop can see because sysop matches all
@hasPermission mob, 'fooPerm'
```

For the command config (only sysops):
Only immortals and sysops can even see the command. Immortals are allowed to
list the configuration values. Sysops can do anything

```CoffeeScript
# ACL: -all +immortal:list +sysop:*
@hasPermission mob
```

Between levels: `+level>=10 -level>20` is eqiv to `20 > level >= 10`

Membership tokens:

 - `all` - Everybody
 - `<group>` - Whatever group, such as sysop, immortal, etc
 - `class=<class>` - Require a certain class
 - `gender=<gender>` - Require a certain gender
 - `ability.<ability><condition><level>` - Require a certain skill with level
 - `level<condition><level>` - Require a certain level

Generic membership tokens:

`<attribute>[~!=<>]<value>` where mob attribute is a stored attribute for
the mob. The conditions are:

 - `~=` - Contains. Equiv to `"<value>" in mob.get <attribute>`
 - `!=` - Not Equal. Equiv to `"<value>" isnt mob.get <attribute>`
 - `=` - Equal. Equiv to `"<value>" is mob.get <attribute>`
 - `<`, `>`, '<=', '>=' - Less than, greater than.
    Equiv to `Number(<value>) > mob.get <attribute>`

TODO: Also allow command completion by looking up permissions

###
class MaskFactory
  rePartSplit: /\s+/
  reMembership: ///
    ^
    ([+-]?)([\w.]+)       # <prefix:1><name:2>: Match just a group or name with
                          # no condition
    (?:
      ([<>]=?)(\d+        # <operator:3><value:4>: Match <, >, <=, >= with
                          # numbers
        (?:\.\d+)?        # Optional decimal point and numbers
      )
      | ([!~]?=)          # <operator:5><value:6,7,8>: Match ~=, !=, = with
                          # anything
      (?:
        (\w+)             # Word with a-z A-Z 0-9 _
        | "([^"]*)"
        | '([^']*)'
      )
      |                   # empty
    )
    (?:
      \:([A-Za-z0-9_\-,]+ # <permission:9>: Match permissions
        |\*)              # or catchall "*"
      |                   # No extra permissions
    )
    (?:
      \s+(.*)             # <rest:10> Match any amount of whitespace before
                          # getting rest
      |                   # empty
     )
    $
  ///
  ###
  Parse the ACL statement in to tokens
  ###
  parse: (acl) ->
    tokens = []
    parts = acl.split /\s+/
    rest = acl
    while rest?.length
      mparts = rest.match @reMembership
      if not mparts?
        throw new Error "ACL membership token '#{acl}' does not match
          membership expression"

      [ match, prefix, name,
        operator, value,
        operator_1, value_1, value_2, value_3,
        permissions, rest] = mparts

      token =
        prefix: prefix
        name: name
        operator: operator or operator_1
        value: value or value_1 or value_2 or value_3
        permissions: permissions?.split ','
        _mparts: mparts

  ###
  Resolve permissions available from acl for the resolver
  ###
  resolve: (acl, resolver) ->
    perms = []
    if not _.isArray acl
      acl = @parse acl

    # Match based on name, operator, value
    ops =
      '>': 'gt'
      '<': 'lt'
      '>=': 'gte'
      '<=': 'lte'
      '!=': 'notEqual'
      '=': 'equal'
      '~=': 'has'
    match = ({name, operator, value}) ->
      return true if name is 'all'
      if not operator?
        return resolver.isTrue name
      return resolver[ops[operator]] name, value

    for term in acl
      continue if not match term
      activePerms = []
      if term.permissions?
        activePerms = activePerms.concat term.permissions

      switch term.prefix
        when '+'
          activePerms.push ''
          perms = perms.concat activePerms
        when '-'
          if activePerms.length is 0
            activePerms.push ''
          perms = _.difference perms, activePerms
        else
          throw new Error "Invalid or no prefix in term for acl #{acl}"

    _.uniq perms

  compile: (acl) ->
    new Mask acl

class Mask extends MaskFactory
  constructor: (@acl) ->
    super()
    @terms = @parse @acl

  resolve: (resolver) ->
    if not resolver?
      throw new Error 'Must specify a resolver'

    super @terms, resolver

  hasPermission: (resolver, permission) ->
    if not resolver?
      throw new Error 'Must specify a resolver'

    permission ?= ''

    perms = @resolve resolver
    return true if permission in perms
    return true if '*' in perms
    false

  toString: -> "[Mask '#{@acl}']"


###
Implements basic functionality for adapting an object to resolver for security
masks.
###
class AttributeResolver
  constructor: (@attributes) ->
  get: (k) ->
    parts = k.split '.'
    obj = @attributes
    while parts.length
      part = parts.shift()
      return null if not obj.hasOwnProperty part
      obj = obj[part]
    obj

  equal: (k, v) ->
    if _.isNumber v
      return v is Number(@get k)

    v is String(@get k)

  gt: (k, v) -> Number(@get(k)) > Number(v)
  lt: (k, v) -> Number(@get(k)) < Number(v)
  gte: (k, v) -> Number(@get(k)) >= Number(v)
  lte: (k, v) -> Number(@get(k)) <= Number(v)
  has: (k, v) -> v in @get k
  notEqual: (k, v) -> not @equal k, v
  isTrue: (k) -> not not @get k

  hasPermission: (mask, permission) ->
    if _.isString mask
      mask = new Mask mask
    mask.hasPermission @, permission

class InsufficientPermissionsError extends Error
  constructor: ({@mob, @mask, @permission}) ->
    super()
    @name = "InsufficientPermissionsError"

  toString: -> "#{@mob} fails permission '#{@permission}' with mask #{@mask}"

exports.MaskFactory = MaskFactory
exports.Mask = Mask
exports.AttributeResolver = AttributeResolver
exports.InsufficientPermissionsError = InsufficientPermissionsError
