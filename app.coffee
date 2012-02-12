window.concertRef = new Firebase('http://gamma.firebase.com:80/concertAppDev');

window.characters = ["punk", "emo", "hooded", "hippie", "eve", "hip", "hannes"]

window.Sprite = Backbone.Model.extend
  initialize: ->
    #console.log("there")
    #this.bind "change", (sprite) ->
      #console.log("SHOU")
      #concertRef.child(sprite.get("id")).set(sprite.toJSON())
      #console.log(sprite.toJSON())
      #concertRef.push(sprite.toJSON())
    
  defaults: ->
    {
      x: 1
      y: 2
      direction: 0
      color: "blue"
      baseVolume: 50
      selfSprite: false
      done: false
      order: 1
      id: "123"
      character: "punk"
      actions: []
      raiseLeft: false
      raiseRight: false
    }
    
  distanceTo: (otherSprite) ->
    x = this.get("x")
    y = this.get("y")
    x0 = otherSprite.get("x")
    y0 = otherSprite.get("y")
    Math.sqrt((x -= x0) * x + (y -= y0) * y);

  angleTo: (otherSprite) ->
    x = this.get("x")
    y = this.get("y")
    x0 = otherSprite.get("x")
    y0 = otherSprite.get("y")
    rad2deg = 180.0 / Math.PI
    Math.atan2(y - y0, x0 - x) * rad2deg + 90
    
  selfSprite: ->
    this.get("id") == App.getSelfSpriteId()

window.SpriteList = Backbone.Collection.extend
  model: Sprite

window.SpriteView = Backbone.View.extend
  tagName: "div"
  template: $("#spriteTemplate").tmpl
  sound: null
  events: {}
  initialize: ->
    if this.model.get("trackId")
      this.sound = SC.stream(this.model.get("trackId"), autoPlay: true, loops: 999, volume: 0)
      
    if this.model.selfSprite()
      this.model.bind('change', this.updateSoundForAllSprites, this)
    this.model.bind('change',  this.render, this)
    this.model.bind('destroy', this.remove, this)
    
    if this.model.selfSprite()
      $(this.el).addClass("self")
    $(this.el).addClass("sprite").addClass(this.model.get("character")).html('<div class="accents"><div class="neck"></div><div class="mohawk"></div><div class="dome"></div><div class="bill"></div><div class="tie"></div><div class="lighter"></div></div><div class="head"><div class="left"></div><div class="right"></div></div><div class="torso"></div><div class="crotch"></div><div class="shoulder left"></div><div class="shoulder right"></div><div class="arm left"></div><div class="arm right"></div><div class="hand left"></div><div class="hand right"></div><div class="leg left"><div class="sock"></div></div><div class="leg right"><div class="sock"></div></div><div class="foot left"></div><div class="foot right"></div>');
    
  render: ->
    $e = $(this.el)
    $e.css
      left: this.model.get("x")
      top:  this.model.get("y")
      zIndex: this.model.get("y")

    for c in characters
      $e.removeClass(c)
    $e.addClass(this.model.get("character"))
    $e.toggleClass("raise_left", this.model.get("raiseLeft"))
    $e.toggleClass("raise_right", this.model.get("raiseRight"))
    this
  
  updateSoundForAllSprites: ->
    for spriteView in window.spriteViews
      if !spriteView.model.get("selfSprite")
        spriteView.updateSound()
    
  updateSound: ->
    if this.sound
      distance = this.model.distanceTo(window.selfSprite)
      volume = Math.max(this.model.get("baseVolume") - (distance / 2), 0)
      relativeAngle = this.model.angleTo(window.selfSprite)
      panningEffect = 80 # how hard is the panning?
      pan = Math.floor(Math.sin(relativeAngle / 360.0 * 2 * Math.PI) * panningEffect)
      this.sound.setVolume(volume)
      this.sound.setPan(pan)
  
  remove: ->
    $(this.el).remove()

walkState = 0;
window.AppView = Backbone.View.extend
  el: $(window)
  events:
    "keydown": "handleKeyDown"
    "keyup": "handleKeyUp"
    
  initialize: ->
    1
    
  render: ->
    #$(this.el).find("#map").html("hi")
    
  getSelfSpriteId: ->
    if !selfSpriteId = localStorage.getItem("selfSpriteId")
      selfSpriteId = "DY" + Math.random()
      localStorage.setItem("selfSpriteId", selfSpriteId)
    
    selfSpriteId
    
  
  handleKeyDown: (e) ->
    
    
    if walkState == 0
      $(spriteViews[0].el).addClass("walk_left")
      walkState = 1
    else
      walkState = 0
      $(spriteViews[0].el).addClass("walk_right")
      
    k = e.keyCode
    #if k == 65
    #  $(spriteViews[0].el).toggleClass("raise_left")
    #if k == 68
    #  $(spriteViews[0].el).toggleClass("raise_right").toggleClass("lighter")

    
    if(k == 38 || k == 39 || k == 40 || k == 37)
      e.preventDefault()
    
  handleKeyUp: (e) ->
    e.originalEvent.preventDefault()
    KN = 38
    KE = 39
    KS = 40
    KW = 37
    apx = 10
    
    always = ->
      $(spriteViews[0].el).removeClass("walk_left").removeClass("walk_right")

    updateSelfAdd = (attr, val) ->
      spriteAttributes = selfSprite.toJSON()
      spriteAttributes[attr] += val
      concertRef.child(selfSprite.get("id")).set(spriteAttributes)
    updateSelf = (attr, val) ->
      spriteAttributes = selfSprite.toJSON()
      spriteAttributes[attr] = val
      concertRef.child(selfSprite.get("id")).set(spriteAttributes)

    switch e.keyCode
      when KN
        updateSelfAdd("y", -apx)
        always()
      when KE
        updateSelfAdd("x", apx)
        always()
      when KS
        updateSelfAdd("y", apx)
        always()
      when KW
        updateSelfAdd("x", -apx)
        always()
      when 65
        updateSelf("raiseLeft", !!selfSprite.get("raiseLeft"))
      when 68
        updateSelf("raiseRight", !!selfSprite.get("raiseRight"))
      when 83
        c = characters[Math.ceil(characters.length * Math.random() + 1)]
        updateSelf("character", c)
      #when 
    

  sprites: {}
  addOne: (sprite) ->
    this.sprites[sprite.get("id")] = sprite
    view = new SpriteView({model: sprite})    
    
    window.spriteViews.push(view)
    $("#map").append(view.render().el)

window.spriteViews = []
window.sprites = {}
initialize = ->
  window.App = new AppView
  
  
  # self
  #window.selfSprite = new Sprite(x: 250, y: 250, color: "#f06", selfSprite: true, character: "emo")
  #App.addOne(selfSprite)

  # dynamic ones
  
  concertRef.on "child_added", (snapshot) ->
    spriteAttributes = snapshot.val()
    sprite = App.sprites[spriteAttributes.id]
    if !sprite
      sprite = new Sprite(snapshot.val())
      if sprite.selfSprite()
        window.selfSprite = sprite
      App.addOne(sprite)
  
  
  concertRef.on "child_changed", (snapshot) ->
    
    
    spriteAttributes = snapshot.val()
    sprite = App.sprites[spriteAttributes.id]
    sprite.set(spriteAttributes)
  
  concertRef.on "child_removed", (snapshot) ->
    spriteAttributes = snapshot.val()
    sprite = App.sprites[spriteAttributes.id]
    sprite.destroy()
  
  
  # create new self sprite
  if !window.selfSprite
    window.selfSprite = new Sprite(x: 280, y: 150, character: "hippie", id: App.getSelfSpriteId())
    App.addOne(selfSprite)
  
  # static sprites
  #App.addOne(new Sprite(x: 280, y: 250, trackId: 17211019, character: "hippie"))
  App.addOne(new Sprite(x: 150, y: 350, trackId: 10985476, baseVolume: 90, character: "punk"))
  App.addOne(new Sprite(x: 210, y: 250, trackId: 293, baseVolume: 70, character: "hip"))

  App.addOne(new Sprite(x: 100, y: 550, trackId: 35303281, baseVolume: 70, character: "hip"))
  App.addOne(new Sprite(x: 600, y: 550, trackId: 5952450, baseVolume: 70, character: "hooded"))



$ ->
  SC.initialize(client_id: "YOUR_CLIENT_ID")
  
  SC.whenStreamingReady ->
    initialize()

    