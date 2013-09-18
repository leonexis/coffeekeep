// Generated by CoffeeScript 1.6.3
(function() {
  var Collection, Mob, MobCollection, Model, _ref, _ref1, _ref2,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  _ref = require('./'), Model = _ref.Model, Collection = _ref.Collection;

  exports.Mob = Mob = (function(_super) {
    __extends(Mob, _super);

    function Mob() {
      _ref1 = Mob.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Mob.prototype.defaults = {
      title: 'Untitled mob',
      location: null
    };

    Mob.prototype.moveTo = function(room) {
      var areaid, last, lastarea, roomid;
      last = this.get('location');
      if (last != null) {
        areaid = last[0], roomid = last[1];
        lastarea = world.areas.get(areaid);
        if (room.area === !lastarea) {
          lastarea.mobs.remove(this);
          return room.area.mobs.add(this);
        }
      } else {
        return room.area.mobs.add(this);
      }
    };

    return Mob;

  })(Model);

  exports.MobCollection = MobCollection = (function(_super) {
    __extends(MobCollection, _super);

    function MobCollection() {
      _ref2 = MobCollection.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    MobCollection.prototype.model = Mob;

    return MobCollection;

  })(Collection);

}).call(this);