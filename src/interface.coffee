# Constructor.
Interface = (name, methods) ->
  throw new Error("Interface constructor called with " + arguments_.length + "arguments, but expected exactly 2.")  unless arguments_.length is 2
  @name = name
  @methods = []
  i = 0
  len = methods.length

  while i < len
    throw new Error("Interface constructor expects method names to be " + "passed in as a string.")  if typeof methods[i] isnt "string"
    @methods.push methods[i]
    i++


# Static class method.
Interface.ensureImplements = (object) ->
  throw new Error("Function Interface.ensureImplements called with " + arguments_.length + "arguments, but expected at least 2.")  if arguments_.length < 2
  i = 1
  len = arguments_.length

  while i < len
    _interface = arguments_[i]
    throw new Error("Function Interface.ensureImplements expects arguments" + "two and above to be instances of Interface.")  if _interface.constructor isnt Interface
    j = 0
    methodsLen = _interface.methods.length

    while j < methodsLen
      method = _interface.methods[j]
      throw new Error("Function Interface.ensureImplements: object " + "does not implement the " + _interface.name + " interface. Method " + method + " was not found.")  if not object[method] or typeof object[method] isnt "function"
      j++
    i++