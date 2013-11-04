myModule =
  myProperty: "someValue"
  
  # object literals can contain properties and methods.
  # here, another object is defined for configuration
  # purposes:
  myConfig:
    useCaching: true
    language: "en"

  
  # a very basic method
  myMethod: ->
    console.log "I can haz functionality?"

  
  # output a value based on current configuration
  myMethod2: ->
    console.log (if "Caching is:" + (@myConfig.useCaching) then "enabled" else "disabled")

  
  # override the current configuration
  myMethod3: (newConfig) ->
    if typeof newConfig is "object"
      @myConfig = newConfig
      console.log @myConfig.language

myModule.myMethod()

# I can haz functionality
myModule.myMethod2()

# outputs enabled
myModule.myMethod3
  language: "fr"
  useCaching: false


# fr