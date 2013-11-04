router = (->
  normalizePath = (path) ->
    path = "/" + path  if path[0] isnt "/"
    path
  
  # Make URL relative
  getRelativeUrl = (url) ->
    url.replace /^(?:\/\/|[^\/]+)*\/?/, ""
  
  # Is an object empty?
  isEmpty = (obj) ->
    for prop of obj
      return false  if obj.hasOwnProperty(prop)
    true
  
  # Get path component of the current URL
  getCurrentPath = (state) ->
    link = document.createElement("a")
    state = History.getState()  if state is `undefined`
    link.href = state.url
    normalizePath link.pathname
  Router = ->
    
    # Replace :[^/]+ with ([^/]+), f.ex. /persons/:id/resource -> /persons/([^/]+)/resource
    
    # Navigate to a path
    
    # Normalize these as undefined if they're empty, different
    # browsers may return different values
    
    # Make absolute path
    
    # Trigger a statechange when just re-navigating to the same
    # state, as History.js won't do this for us
    #console.log('State hasn\'t changed, just triggering a statechange');
    
    # Get pathname part of URL, which is what we'll be matching
    
    #console.log("Route " + route + ", " + path + ", match: " + match);
    
    # Translate groups to parameters
    
    #console.log('Route ' + route  + ' matched, arguments: ' + match.slice(1));
    onStateChange = ->
      
      #console.log('statechange');
      self.perform()
    self = this
    self.routes = {}
    self.route = (path, func) ->
      route = undefined
      path = normalizePath(path)
      route = "^" + path.replace(/:\w+/g, "([^/]+)") + "$"
      self.routes[route] = func
      self

    self.navigate = (path, data, title) ->
      currentState = History.getState()
      currentUrl = undefined
      currentTitle = undefined
      currentData = undefined
      currentUrl = currentState.url
      currentData = currentState.data
      currentTitle = currentState.title
      currentData = `undefined`  if isEmpty(currentData)
      currentTitle = `undefined`  unless currentTitle
      if path[0] isnt "/"
        currentPath = getCurrentPath()
        currentPath += "/"  if currentPath.slice(-1)[0] isnt "/"
        path = currentPath + path
      if path isnt normalizePath(getRelativeUrl(currentUrl)) or data isnt currentData or title isnt currentTitle
        History.pushState data, title, path
      else
        $(window).trigger "statechange"
      self

    self.perform = ->
      state = History.getState()
      path = getCurrentPath(state)
      route = undefined
      rx = undefined
      match = undefined
      func = undefined
      for route of self.routes
        if self.routes.hasOwnProperty(route)
          rx = new RegExp(route)
          match = rx.exec(path)
          if match isnt null
            func = self.routes[route]
            func.apply state, match.slice(1)
            break
      self

    self.back = ->
      History.back()
      self

    self.go = (steps) ->
      History.go steps
      self

    History.Adapter.bind window, "statechange", onStateChange
  Router: Router
())