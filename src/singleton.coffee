Singleton = (->
  init = ->
    
    # singleton here
    publicMethod: ->
      console.log "hello world"

    publicProperty: "test"
  instantiated = undefined
  getInstance: ->
    instantiated = init()  unless instantiated
    instantiated
)()

# calling public methods is then as easy as:
Singleton.getInstance().publicMethod()