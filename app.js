(function() {
  var initialize, walkState;
  window.concertRef = new Firebase('http://gamma.firebase.com:80/concertAppDev');
  window.Sprite = Backbone.Model.extend({
    initialize: function() {},
    defaults: function() {
      return {
        x: 1,
        y: 2,
        direction: 0,
        color: "blue",
        baseVolume: 50,
        selfSprite: false,
        done: false,
        order: 1,
        id: "123",
        character: "punk",
        actions: [],
        raiseLeft: false,
        raiseRight: false,
        idleSince: 0,
        npc: false
      };
    },
    distanceTo: function(otherSprite) {
      var x, x0, y, y0;
      x = this.get("x");
      y = this.get("y");
      x0 = otherSprite.get("x");
      y0 = otherSprite.get("y");
      return Math.sqrt((x -= x0) * x + (y -= y0) * y);
    },
    angleTo: function(otherSprite) {
      var rad2deg, x, x0, y, y0;
      x = this.get("x");
      y = this.get("y");
      x0 = otherSprite.get("x");
      y0 = otherSprite.get("y");
      rad2deg = 180.0 / Math.PI;
      return Math.atan2(y - y0, x0 - x) * rad2deg + 90;
    },
    selfSprite: function() {
      return this.get("id") === App.getSelfSpriteId();
    }
  });
  window.SpriteList = Backbone.Collection.extend({
    model: Sprite
  });
  window.SpriteView = Backbone.View.extend({
    tagName: "div",
    template: $("#spriteTemplate").tmpl,
    sound: null,
    events: {},
    initialize: function() {
      if (this.model.get("trackId")) {
        this.sound = SC.stream(this.model.get("trackId"), {
          autoPlay: true,
          loops: 999,
          volume: 0
        });
      }
      if (this.model.selfSprite()) {
        this.model.bind('change', this.updateSoundForAllSprites, this);
      }
      this.model.bind('change', this.render, this);
      this.model.bind('destroy', this.remove, this);
      if (this.model.selfSprite()) {
        $(this.el).addClass("self");
      }
      return $(this.el).addClass("sprite").addClass(this.model.get("character")).html('<div class="accents"><div class="neck"></div><div class="mohawk"></div><div class="dome"></div><div class="bill"></div><div class="tie"></div><div class="lighter"></div></div><div class="head"><div class="left"></div><div class="right"></div></div><div class="torso"></div><div class="crotch"></div><div class="shoulder left"></div><div class="shoulder right"></div><div class="arm left"></div><div class="arm right"></div><div class="hand left"></div><div class="hand right"></div><div class="leg left"><div class="sock"></div></div><div class="leg right"><div class="sock"></div></div><div class="foot left"></div><div class="foot right"></div>');
    },
    render: function() {
      var $e, c, _i, _len, _ref;
      $e = $(this.el);
      $e.css({
        left: this.model.get("x"),
        top: this.model.get("y"),
        zIndex: this.model.get("y")
      });
      _ref = App.characters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        $e.removeClass(c);
      }
      $e.addClass(this.model.get("character"));
      $e.toggleClass("raise_left", this.model.get("raiseLeft"));
      $e.toggleClass("raise_right", this.model.get("raiseRight"));
      return this;
    },
    updateSoundForAllSprites: function() {
      var spriteView, _i, _len, _ref, _results;
      _ref = window.spriteViews;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        spriteView = _ref[_i];
        _results.push(!spriteView.model.selfSprite() ? spriteView.updateSound() : void 0);
      }
      return _results;
    },
    updateSound: function() {
      var distance, pan, panningEffect, relativeAngle, volume;
      if (this.sound) {
        distance = this.model.distanceTo(window.selfSprite);
        volume = Math.max(this.model.get("baseVolume") - (distance / 2), 0);
        relativeAngle = this.model.angleTo(window.selfSprite);
        panningEffect = 80;
        pan = Math.floor(Math.sin(relativeAngle / 360.0 * 2 * Math.PI) * panningEffect);
        this.sound.setVolume(volume);
        return this.sound.setPan(pan);
      }
    },
    remove: function() {
      return $(this.el).remove();
    }
  });
  walkState = 0;
  window.AppView = Backbone.View.extend({
    el: $(window),
    events: {
      "keydown": "handleKeyDown",
      "keyup": "handleKeyUp"
    },
    characters: ["punk", "emo", "hooded", "hippie", "eve", "hip", "hannes"],
    moves: ["raise_right", "raise_left", "raise_right lighter", "walk_left", "walk_right", "", "", ""],
    initialize: function() {
      return 1;
    },
    render: function() {},
    getSelfSpriteId: function() {
      var selfSpriteId;
      if (!(selfSpriteId = localStorage.getItem("selfSpriteId"))) {
        selfSpriteId = "DY" + Math.random();
        localStorage.setItem("selfSpriteId", selfSpriteId);
      }
      return selfSpriteId;
    },
    randomCharacter: function() {
      return this.randomArrayElement(App.characters);
    },
    randomArrayElement: function(arr) {
      return arr[Math.ceil(arr.length * Math.random() - 1)];
    },
    handleKeyDown: function(e) {
      var k;
      if (walkState === 0) {
        $(spriteViews[0].el).addClass("walk_left");
        walkState = 1;
      } else {
        walkState = 0;
        $(spriteViews[0].el).addClass("walk_right");
      }
      k = e.keyCode;
      if (k === 38 || k === 39 || k === 40 || k === 37) {
        return e.preventDefault();
      }
    },
    handleKeyUp: function(e) {
      var always, apx, c, updateSelf, updateSelfAdd;
      e.originalEvent.preventDefault();
      apx = 10;
      always = function() {
        var $s, $w, border, sRightEdgePosition;
        $(spriteViews[0].el).removeClass("walk_left").removeClass("walk_right");
        $s = $(App.selfSpriteView.el);
        $w = $(window);
        sRightEdgePosition = $s.position().left + $s.width();
        border = 100;
        if (sRightEdgePosition + border > $w.width() + $w.scrollLeft()) {
          $w.scrollLeft(sRightEdgePosition + border - $w.width());
        }
        if ($s.position().left < $w.scrollLeft() + border) {
          return $(window).scrollLeft($s.position().left - border);
        }
      };
      updateSelfAdd = function(attr, val) {
        var spriteAttributes;
        spriteAttributes = selfSprite.toJSON();
        spriteAttributes[attr] += val;
        return concertRef.child(selfSprite.get("id")).set(spriteAttributes);
      };
      updateSelf = function(attr, val) {
        var spriteAttributes;
        spriteAttributes = selfSprite.toJSON();
        spriteAttributes[attr] = val;
        return concertRef.child(selfSprite.get("id")).set(spriteAttributes);
      };
      switch (e.keyCode) {
        case 38:
          updateSelfAdd("y", -apx);
          return always();
        case 39:
          updateSelfAdd("x", apx);
          return always();
        case 40:
          updateSelfAdd("y", apx);
          return always();
        case 37:
          updateSelfAdd("x", -apx);
          return always();
        case 65:
          return updateSelf("raiseLeft", !!selfSprite.get("raiseLeft"));
        case 68:
          return updateSelf("raiseRight", !!selfSprite.get("raiseRight"));
        case 83:
          c = App.randomCharacter();
          return updateSelf("character", c);
      }
    },
    sprites: {},
    addOne: function(sprite) {
      var view;
      this.sprites[sprite.get("id")] = sprite;
      view = new SpriteView({
        model: sprite
      });
      window.spriteViews.push(view);
      $("#map").append(view.render().el);
      return view;
    }
  });
  window.spriteViews = [];
  window.sprites = {};
  initialize = function() {
    window.App = new AppView;
    concertRef.on("child_added", function(snapshot) {
      var sprite, spriteAttributes, spriteView;
      spriteAttributes = snapshot.val();
      sprite = App.sprites[spriteAttributes.id];
      if (!sprite) {
        sprite = new Sprite(snapshot.val());
        if (sprite.selfSprite()) {
          window.selfSprite = sprite;
        }
        spriteView = App.addOne(sprite);
        if (sprite.selfSprite()) {
          return App.selfSpriteView = sprite;
        }
      }
    });
    concertRef.on("child_changed", function(snapshot) {
      var sprite, spriteAttributes;
      spriteAttributes = snapshot.val();
      sprite = App.sprites[spriteAttributes.id];
      if (sprite) {
        return sprite.set(spriteAttributes);
      }
    });
    concertRef.on("child_removed", function(snapshot) {
      var sprite, spriteAttributes;
      spriteAttributes = snapshot.val();
      sprite = App.sprites[spriteAttributes.id];
      return sprite.destroy();
    });
    if (!window.selfSprite) {
      window.selfSprite = new Sprite({
        x: 280,
        y: 150,
        character: App.randomCharacter(),
        id: App.getSelfSpriteId()
      });
      App.selfSpriteView = App.addOne(selfSprite);
    }
    App.addOne(new Sprite({
      x: 150,
      y: 350,
      trackId: 10985476,
      baseVolume: 90,
      npc: true,
      character: "punk"
    }));
    App.addOne(new Sprite({
      x: 210,
      y: 250,
      trackId: 293,
      baseVolume: 70,
      npc: true,
      character: "hip"
    }));
    App.addOne(new Sprite({
      x: 100,
      y: 550,
      trackId: 35303281,
      baseVolume: 70,
      npc: true,
      character: "hip"
    }));
    App.addOne(new Sprite({
      x: 600,
      y: 550,
      trackId: 5952450,
      baseVolume: 70,
      npc: true,
      character: "hooded"
    }));
    App.addOne(new Sprite({
      x: 600,
      y: 150,
      trackId: 19636456,
      baseVolume: 100,
      npc: true,
      character: "hooded"
    }));
    App.addOne(new Sprite({
      x: 300,
      y: 700,
      trackId: 13562452,
      baseVolume: 100,
      npc: true,
      character: "emo"
    }));
    return App.addOne(new Sprite({
      x: 300,
      y: 300,
      trackId: 35156056,
      baseVolume: 100,
      npc: true,
      character: "punk"
    }));
  };
  $(function() {
    SC.initialize({
      client_id: "YOUR_CLIENT_ID"
    });
    return SC.whenStreamingReady(function() {
      return initialize();
    });
  });
  window.setInterval(function() {
    var $sv, m, sv, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = spriteViews.length; _i < _len; _i++) {
      sv = spriteViews[_i];
      _results.push((function() {
        var _j, _len2, _ref;
        if (Math.random() > 0.7 && sv.model.get("npc")) {
          $sv = $(sv.el);
          _ref = App.moves;
          for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
            m = _ref[_j];
            $sv.removeClass(m);
          }
          return $sv.addClass(App.randomArrayElement(App.moves));
        }
      })());
    }
    return _results;
  }, 500);
}).call(this);
