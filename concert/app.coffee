window.fb = new Firebase('http://gamma.firebase.com:80/concertAppDev')
window.concertRef = window.fb.child('sprites')
window.actions    = window.fb.child('actions')

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
      lighter: false
      idleSince: 0
      npc: false
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
    $(this.el).addClass("sprite").addClass(this.model.get("character")).html('<span class="scream"></span><div class="accents"><div class="skirt"></div><div class="sideburns"><div class="left"></div><div class="right"></div></div><div class="ponytail"><div class="left"></div><div class="right"></div></div><div class="neck"></div><div class="mohawk"></div><div class="dome"></div><div class="bill"></div><div class="tie"></div><div class="belt"><div class="buckle"></div></div><div class="lighter"></div></div><div class="head"><div class="left"></div><div class="right"></div><div class="mouth"></div></div><div class="torso"><div class="tube"></div></div><div class="crotch"></div><div class="shoulder left"></div><div class="shoulder right"></div><div class="arm left"><div class="elbow"></div><div class="hand"></div></div><div class="arm right"><div class="elbow"></div><div class="hand"></div></div><div class="leg left"><div class="sock"></div></div><div class="leg right"><div class="sock"></div></div><div class="foot left"></div><div class="foot right"></div>');
    
  render: ->
    $e = $(this.el)
    $e.css
      left: this.model.get("x")
      top:  this.model.get("y")
      zIndex: this.model.get("y")

    for c in App.characters
      $e.removeClass(c)
    $e.addClass(this.model.get("character"))
    $e.attr("id", this.model.get("id"))
    $e.toggleClass("raise_left", this.model.get("raiseLeft"))
    $e.toggleClass("raise_right", this.model.get("raiseRight"))
    $e.toggleClass("lighter raise_right", this.model.get("ligther"))
    
    this
  
  updateSoundForAllSprites: ->
    for spriteView in window.spriteViews
      if !spriteView.model.selfSprite()
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
    
  scream: (text, callback) ->
    $el = $(this.el)
    $el.find(".scream").text(text).css("display", "initial");
    $el.addClass("shout")
    window.setTimeout ->
      $el.removeClass("shout")
      $el.find(".scream").fadeOut "slow", ->
        callback() if callback?
    , 3000

walkState = 0;
window.AppView = Backbone.View.extend
  el: $(window)
  events:
    "keydown": "handleKeyDown"
    "keyup": "handleKeyUp"

  characters: ["punk", "emo", "hooded", "hippie", "eve", "hip", "hannes", "ty", "paul", "chick", "pig"]
  moves:      ["raise_right", "raise_left", "raise_right lighter", "walk_left", "walk_right", "", "", "", "shout", "shout"]
  initialize: ->
    1

  render: ->
    #$(this.el).find("#map").html("hi")

  getSelfSpriteId: ->
    if !selfSpriteId = localStorage.getItem("selfSpriteId")
      selfSpriteId = "DY" + Math.random()
      localStorage.setItem("selfSpriteId", selfSpriteId)
    selfSpriteId

  randomCharacter: ->
    this.randomArrayElement(App.characters)

  randomArrayElement: (arr) -> 
    arr[Math.ceil(arr.length * Math.random() - 1)]

  handleKeyDown: (e) ->
    if walkState == 0
      $(spriteViews[0].el).addClass("walk_left")
      walkState = 1
    else
      walkState = 0
      $(spriteViews[0].el).addClass("walk_right")
      
    k = e.keyCode
    if(k == 38 || k == 39 || k == 40 || k == 37)
      e.preventDefault()
    
  handleKeyUp: (e) ->
    e.originalEvent.preventDefault()
    apx = 10
    
    always = ->
      $(spriteViews[0].el).removeClass("walk_left").removeClass("walk_right")
      $s = $(App.selfSpriteView.el)
      $w = $(window)
      sRightEdgePosition = $s.position().left + $s.width()
      sBottomEdgePosition = $s.position().top + $s.height()
      border = 100
      if sRightEdgePosition + border > $w.width() + $w.scrollLeft()
        $w.scrollLeft(sRightEdgePosition + border - $w.width())
        
      if $s.position().left < $w.scrollLeft() + border 
        $(window).scrollLeft($s.position().left - border)
      # scroll up & down

    updateSelfAdd = (attr, val) ->
      spriteAttributes = selfSprite.toJSON()
      spriteAttributes[attr] += val
      concertRef.child(selfSprite.get("id")).set(spriteAttributes)
    updateSelf = (attr, val) ->
      spriteAttributes = selfSprite.toJSON()
      spriteAttributes[attr] = val
      concertRef.child(selfSprite.get("id")).set(spriteAttributes)
    switch e.keyCode
      when 38 # north
        updateSelfAdd("y", -apx)
        always()
      when 39 # east
        updateSelfAdd("x", apx)
        always()
      when 40 # souht
        updateSelfAdd("y", apx)
        always()
      when 37 # west
        updateSelfAdd("x", -apx)
        always()
      when 65 # A
        updateSelf("raiseLeft", !selfSprite.get("raiseLeft"))
      when 68 # D
        updateSelf("raiseRight", !selfSprite.get("raiseRight"))
      when 90 # D
        updateSelf("ligther", !selfSprite.get("lighter"))
      when 83 # S
        c = App.randomCharacter()
        updateSelf("character", c)
      when 84 # T
        App.fireAction(text: prompt("What do you want to scream?"))
      when 81 # Q
        App.fireAction(trackId: 36401932)

  sprites: {}
  addOne: (sprite) ->
    this.sprites[sprite.get("id")] = sprite
    view = new SpriteView({model: sprite})    
    
    window.spriteViews.push(view)
    $("#map").append(view.render().el)
    view
    
    
  fireAction: (action) -> 
    action.sqid = App.getSelfSpriteId()
    actions.push action

  handleAction: (action) ->
    if sv = this.findSpriteViewForId(action.sqid)
      if action.text
        sv.scream(action.text)

      if action.trackId
        SC.stream action.trackId,
          autoPlay:true
          volume: 30
          onfinish: ->
            #console.log('done')
          
  findSpriteViewForId: (id) ->
    spriteView = null
    for sv in spriteViews
      if sv.model.get("id") == id
        spriteView = sv
    spriteView

window.spriteViews = []
window.sprites = {}
initialize = ->
  window.App = new AppView

  actions.on "child_added", (snapshot) ->
    attrs = snapshot.val()
    sqid = attrs.sqid
    if App.getSelfSpriteId() == sqid
      node = window.actions.child(snapshot.name())
      if node
        setTimeout((-> node.remove (a)-> console.log("Action removed.")), 1000)
    App.handleAction(attrs)

  concertRef.on "child_added", (snapshot) ->
    spriteAttributes = snapshot.val()
    sprite = App.sprites[spriteAttributes.id]
    if !sprite
      sprite = new Sprite(snapshot.val())
      if sprite.selfSprite()
        window.selfSprite = sprite
      spriteView = App.addOne(sprite)
      if sprite.selfSprite()
        App.selfSpriteView = sprite 

  concertRef.on "child_changed", (snapshot) ->
    spriteAttributes = snapshot.val()
    #spriteAttributes.set()
    sprite = App.sprites[spriteAttributes.id]
    if sprite
      sprite.set(spriteAttributes)

  concertRef.on "child_removed", (snapshot) ->
    spriteAttributes = snapshot.val()
    sprite = App.sprites[spriteAttributes.id]
    sprite.destroy()

  # create new self sprite. right now happens always due to race condition
  if !window.selfSprite
    window.selfSprite = new Sprite(x: 280, y: 150, character: App.randomCharacter(), id: App.getSelfSpriteId())
    App.selfSpriteView = App.addOne(selfSprite)

  # static sprites
  #App.addOne(new Sprite(x: 280, y: 250, trackId: 17211019, character: "hippie"))
  
#  App.addOne(new Sprite(x: 150, y: 350, trackId: 10985476, baseVolume: 90,  npc: true, character: "punk"))
  
  # weird girl left
  weirdGirlSV = App.addOne(new Sprite(x: 50, y: 230, trackId: 13562452,      baseVolume: 40,  npc: true, character: "pig"))
  # puker left bottom
  App.addOne(new Sprite(x: 100, y: 550, trackId: 8106355, baseVolume: 100,  npc: true, character: "punk"))
  # screaming chick
  App.addOne(new Sprite(x: 600, y: 550, trackId: 5952450,  baseVolume: 90,  npc: true, character: "chick"))
  
  App.addOne(new Sprite(x: 600, y: 150, trackId: 19636456, baseVolume: 100, npc: true, character: "hooded"))
  App.addOne(new Sprite(x: 300, y: 700, trackId: 13562452, baseVolume: 110, npc: true, character: "emo"))
  
  
  App.addOne(new Sprite(x: 300, y: 300, trackId: 35156056, baseVolume: 120, npc: true, character: "punk"))
  # ty selling beer
  App.addOne(new Sprite(x: 500, y: 300, trackId: 36399494, baseVolume: 125, npc: true, character: "ty"))
  # raging crowd
  App.addOne(new Sprite(x: 800, y: 300, trackId: 21287304, baseVolume: 150, npc: true, character: "pig"))
  App.addOne(new Sprite(x: 850, y: 350, trackId: 21287304, baseVolume: 150, npc: true, character: "hip"))
  App.addOne(new Sprite(x: 750, y: 320, trackId: 21287304, baseVolume: 150, npc: true, character: "hip"))


  # snopp
  App.addOne(new Sprite(x: 800, y: 50, trackId: 6287454, baseVolume: 110, npc: true, character: "paul"))
  
  # cheering
  
  #App.addOne(new Sprite(x: 800, y: 50, trackId: 30358843, baseVolume: 100, npc: true, character: "paul"))
  
  # background track
  
  
  trackId = window.location.hash.split("#")[1] || 20935195
  SC.stream(trackId, autoPlay: true, loops: 999, volume: 18)
  
  weirdGirlSV.scream "Hi!", ->
    weirdGirlSV.scream "Use the arrow keys to walk around and listen", ->
      weirdGirlSV.scream "Press 'T' to scream something and 'Q' to boo", ->
        weirdGirlSV.scream "Have fun!"
        
      
    
  
  

$ ->
  SC.initialize(client_id: "YOUR_CLIENT_ID")
  SC.whenStreamingReady ->
    initialize()

window.setInterval ->
  for sv in spriteViews
    if Math.random() > 0.7 && sv.model.get("npc") #!sv.model.selfSprite() # only:  sv.model.get("npc")
      $sv = $(sv.el)
      for m in App.moves
        $sv.removeClass(m)
      $sv.addClass App.randomArrayElement(App.moves)
, 500

    
