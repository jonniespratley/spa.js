###
spa.js Framework

@version 1.0.0
@license MIT-License <http://opensource.org/licenses/MIT>

Copyright (c) 2013 spa.js

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
###

###
spa.js Framework
###
define ->
  "use strict"
  
  ###
  The main spa object
  @type {Object}
  ###
  spa =
    
    ###
    Container for all routes
    @type {Object}
    ###
    routes: {}
    
    ###
    Container for all module objects
    @type {Object}
    ###
    scope: {}
    
    ###
    Conatiner for all dependencies
    @type {Object}
    ###
    dependencies: {}
    
    ###
    Container for all models
    @type {Object}
    ###
    models: {}
    
    ###
    Container for all defined xhr requests
    @type {Object}
    ###
    requests: {}
    
    ###
    @method init
    
    Adds module to spa object, sets up core properties and initializes router
    ###
    init: ->
      module = undefined
      _this = this
      i = undefined
      max = undefined
      
      # Make available in global scope
      window.spa = this
      require @modules, ->
        
        # Load modules into application scope
        i = 0
        max = arguments_.length

        while i < max
          module = _this.modules[i].split("/").pop()
          _this.scope[module] = arguments_[i]
          
          # Add module-id to scope
          _this.scope[module].mid = module
          
          # Create element reference
          _this.scope[module].el = document.querySelectorAll("[data-view='" + module + "']")
          
          # If jQuery is available create jQuery accessible DOM reference
          _this.scope[module].$el = jQuery("[data-view='" + module + "']")  if typeof jQuery isnt "undefined"
          
          # Create module.forEachEl
          _this.scope[module].forEachEl = _this.forEachEl
          i++
        
        # Call the router
        _this.router()

      
      # Polyfill for bind()
      @polyfill_bind()  unless Function::bind

    
    ###
    @method router
    
    Sets up Routing Table, binds and loads Routes
    ###
    router: ->
      cur_route = window.location.hash
      _this = this
      module = undefined
      route = undefined
      for module of @scope
        if @scope.hasOwnProperty(module)
          for route of @scope[module].routes
            unless @routes.hasOwnProperty(route)
              @routes[route] = [[module, @scope[module].routes[route]]]
            else
              @routes[route].push [module, @scope[module].routes[route]]
      
      # Initial route
      @loadUrl cur_route
      
      # Bind change
      window.onhashchange = ->
        _this.loadUrl window.location.hash

    
    ###
    @method loadUrl
    
    Checks to verify that current route matches a module's route, passes it to the processor() and hides all modules that don't need to be rendered
    
    @param {String} fragment The current hash
    ###
    loadUrl: (fragment) ->
      _this = this
      querystring = false
      url_data = {}
      qs_data = undefined
      el_lock = undefined
      module_name = undefined
      route = undefined
      i = undefined
      max = undefined
      _i = undefined
      _max = undefined
      bits = undefined
      
      # Break apart fragment
      fragment = fragment.replace("#!/", "")
      
      # Check for and remove trailing slash
      fragment = fragment.substr(0, fragment.length - 1)  if fragment.substr(-1) is "/"
      
      # Split off any querystrings
      fragment = fragment.split("?")
      querystring = fragment[1]  if fragment[1]
      
      # Check for URL Data - Slash delimited
      fragment = fragment[0].split("/")
      if fragment.length > 0
        i = 1
        max = fragment.length

        while i < max
          url_data[i - 1] = fragment[i]
          i++
      
      # Add Querystring data to URL Data object
      if querystring
        qs_data = querystring.split("&")
        i = 0
        max = qs_data.length

        while i < max
          bits = qs_data[i].split("=")
          url_data[bits[0]] = bits[1]
          i++
      
      # Store current route
      _this.current_route = fragment[0]
      
      # Store url data
      _this.url_data = url_data
      
      # Check route for match(es)
      for route of _this.routes
        if _this.routes.hasOwnProperty(route)
          _i = 0
          _max = _this.routes[route].length

          while _i < _max
            
            # Get Name
            module_name = _this.routes[route][_i][0]
            
            # Check route for match
            if fragment[0] is route or route is "*"
              if el_lock isnt module_name
                
                # Prevents other routes in the same module from hiding this
                el_lock = module_name
                
                # Send module to processor
                _this.processor module_name, _this.routes[route][_i][1], url_data
            else
              
              # Clear & Hide sections that don't exist in current route
              _this.unrender module_name
            _i++

    
    ###
    @method processor
    
    Handles processing of the module, loads template, fires dependency loader then the route event
    
    @param {Object} module The module object to be used.
    @param {Function} route_fn The return function from the route.
    @param {Object} url_data The data from any url query strings
    ###
    processor: (module, route_fn, url_data) ->
      scope = @scope[module]
      _this = this
      
      # Set module to loaded
      scope.loaded = true
      
      # Check to see if we are using inline template or if template has already been loaded/defined
      unless scope.hasOwnProperty("template")
        
        # Get the template
        _this.ajax
          url: "templates/" + scope.mid + ".tpl"
          type: "GET"
          success: (data) ->
            scope.template = data
            _this.loadDependencies scope, ->
              
              # Run route after deps are loaded
              scope[route_fn] url_data


          error: ->
            console.log "Could not load template for " + scope.mid

      else
        _this.loadDependencies scope, ->
          
          # Run route after deps are loaded
          scope[route_fn] url_data


    
    ###
    @method loadDependencies
    
    Checks for & loads any dependencies before calling the route's function
    
    @param {Object} scope The module object to be used.
    @param {Function} callback Function to execute when all deps are loaded
    ###
    loadDependencies: (scope, callback) ->
      _this = this
      i = undefined
      max = undefined
      dep = undefined
      dep_name = undefined
      dep_src = undefined
      arr_dep_name = []
      arr_dep_src = []
      
      # Load module's dependencies
      if scope.hasOwnProperty("dependencies")
        
        # Build Dependency Arrays
        for dep of scope.dependencies
          if scope.dependencies.hasOwnProperty(dep)
            dep_name = dep
            dep_src = scope.dependencies[dep]
            
            # Check if already loaded into global
            if _this.dependencies.hasOwnProperty(dep_src)
              scope[dep_name] = _this.dependencies[dep_src]
            
            # Add to array to be pulled via Require
            else
              arr_dep_name.push dep_name
              arr_dep_src.push dep_src
        
        # Load deps and add to object
        require arr_dep_src, ->
          i = 0
          max = arguments_.length

          while i < max
            scope[arr_dep_name[i]] = arguments_[i]
            
            # Store in globally accessible dependencies object
            _this.dependencies[arr_dep_src[i]] = arguments_[i]
            i++
          
          # Fire callback
          callback scope  if callback and typeof callback is "function"

      
      # Module has no dependencies
      else
        
        # Fire callback
        callback scope  if callback and typeof callback is "function"

    
    ###
    @method render
    
    Renders a module's template onto the screen
    
    @param {Object} scope The module object to be used.
    @param {Object} [data] Any data to be rendered onto the template.
    ###
    render: (scope, data) ->
      _this = this
      template = scope.template
      templateRender = undefined
      rendered = undefined
      max = undefined
      el = undefined
      i = undefined
      
      # filter function for the template
      templateRender = (i, match) ->
        data[match]

      max = scope.el.length
      i = 0

      while i < max
        
        # Get element
        el = scope.el[i]
        
        # Replace any mustache-style {{VAR}}'s
        rendered = template.replace(/\{\{([^}]+)\}\}/g, templateRender)
        
        # Render to DOM & Show Element
        el.innerHTML = rendered
        el.style.display = "block"
        i++
      
      # Build Event Listeners
      _this.delegateEvents scope.events, scope

    
    ###
    @method unrender
    
    Removes unused modules' content from DOM and sets display to none
    
    @param {String} module_name The name of the module to unrender
    ###
    unrender: (module_name) ->
      index = undefined
      el = undefined
      max = undefined
      el = document.querySelectorAll("[data-view='" + module_name + "']")
      index = 0
      max = el.length

      while index < max
        el[index].innerHTML = ""
        el[index].style.display = "none"
        index++

    
    ###
    @method access
    
    Proxy function for accessing other modules and their dependencies
    
    @param {Object} module Name of the module to access
    @param {Function} callback The function to fire once access is complete
    ###
    access: (module, callback) ->
      _this = this
      scope = @scope[module]
      unless scope.hasOwnProperty("loaded")
        
        # Not previously loaded, check for dependencies
        _this.loadDependencies scope, (scope) ->
          scope.loaded = true
          callback scope  if callback and typeof callback is "function"

      else
        
        # Module previously loaded, fire callback
        callback scope  if callback and typeof callback is "function"

    
    ###
    @method navigate
    
    Responsible for updating the history hash, and changing the URL
    
    @param  {String} fragment The location to be loaded
    @return {Boolean}
    ###
    navigate: (fragment) ->
      location = window.location
      root = location.pathname.replace(/[^\/]$/, "$&")
      _this = this
      url = undefined
      
      # Handle url composition
      if fragment.length
        
        # Fragment exists
        url = root + location.search + "#!/" + fragment
      else
        
        # Null/Blank fragment, nav to root
        url = root + location.search
      if history.pushState
        
        # Browser supports pushState()
        history.pushState null, document.title, url
        _this.loadUrl fragment
      else
        
        # Older browser fallback
        location.replace root + url
      true

    
    ###
    @method delegateEvents
    
    Binds callbacks for a module's events object
    
    @param {Object} events Events to be watched for
    @param {Object} scope The current module
    ###
    delegateEvents: (events, scope) ->
      delegateEventSplitter = /^(\S+)\s*(.*)$/
      _this = this
      method = undefined
      match = undefined
      event_name = undefined
      selector = undefined
      nodes = undefined
      key = undefined
      max = undefined
      i = undefined
      
      # if there are no events on this sectional then we move on
      return  unless events
      for key of events
        if events.hasOwnProperty(key)
          method = events[key]
          match = key.match(delegateEventSplitter)
          event_name = match[1]
          selector = match[2]
          
          #
          #                     * bind method on event for selector on scope.mid
          #                     * the caller function has access to event, spa, scope
          #                     
          nodes = document.querySelectorAll("[data-view='" + scope.mid + "'] " + selector)
          i = 0
          max = nodes.length

          while i < max
            _this.bindEvent nodes[i], event_name, scope[method].bind(scope), true
            i++

    
    ###
    @method bindEvent
    
    Used to bind events to DOM objects
    
    @param {Object} el Element on which to attach event
    @param {String} evt Event name
    @param {Function} fn Function to be called
    @param {Boolean} [pdef] Boolean to preventDefault
    ###
    bindEvent: (el, evt, fn, pdef) ->
      pdef = pdef or false
      if el.addEventListener # Modern browsers
        el.addEventListener evt, ((event) ->
          (if event.preventDefault then event.preventDefault() else event.returnValue = false)  if pdef
          fn event
        ), false
      else # IE <= 8
        el.attachEvent "on" + evt, (event) ->
          (if event.preventDefault then event.preventDefault() else event.returnValue = false)  if pdef
          fn event


    
    ###
    @method model
    
    Allows for local API model create, read, and delete
    
    @param {String} name The name of the model
    @param {Object} [data] Contents of the model, blank to return, 'null' to clear
    
    Specify a object value to `set`, none to `get`, and 'null' to `clear`
    ###
    model: ->
      _this = this
      name = undefined
      model = undefined
      params = undefined
      
      # If first argument is an object, create model
      if typeof arguments_[0] is "object"
        params = arguments_[0]
        
        # Check optional parameters
        params.url = params.url or false
        params.onchange = params.onchange or false
        
        # Core properties
        if typeof params.name is "string" and params.name isnt ""
          _this.models[params.name] =
            data: params.data
            
            # Define save method, ex: spa.model('some_model').get();
            get: _this.sync.bind(_this, params.name, "GET")
            
            # Define get method, ex: spa.model('some_model').put();
            put: _this.sync.bind(_this, params.name, "PUT")
            
            # Define post method, ex: spa.model('some_model').post();
            post: _this.sync.bind(_this, params.name, "POST")
            
            # Define delete method, ex: spa.model('some_model').delete;
            delete: _this.sync.bind(_this, params.name, "DELETE")

          
          # If URL of endpoint supplied, set property
          _this.models[params.name].url = params.url  if params.url
          
          # If onchange fn is specified, set as property
          _this.models[params.name].onchange = params.onchange  if params.onchange
          
          # If onsync fn is specified, set as property
          _this.models[params.name].onsync = params.onsync  if params.onsync
          
          # Return the model
          _this.models[params.name]
        else
          throw new Error("Cannot create a null model")
      
      # Modify existing object
      else if arguments_.length is 2
        name = arguments_[0]
        model = _this.models[name]
        
        # Modify data
        if typeof arguments_[1] is "object" and arguments_[1] isnt null
          model.data = arguments_[1]
          
          # Fire onchange
          model.onchange model.data  if model.hasOwnProperty("onchange")
          
          # Publish for any subscriptions
          _this.publish "model_" + name + "_change", model.data
        
        # Delete model
        else
          delete _this.models[name]
      
      # Return model
      else
        name = arguments_[0]
        model = _this.models[name]
        model

    
    ###
    @method sync
    
    Gets bound to models, used to access API
    
    @param {String} name Name of the model
    @param {String} method RESTful request method
    ###
    sync: (name, method) ->
      model = @models[name]
      sendback = {}
      
      # Define call
      _this = this
      url = @parseURL(model.url, model.data)
      data = model.data
      syncParams =
        url: url
        type: method
        data: data
        qsData: false
        success: (returnData) ->
          
          # Set sendback
          sendback.status = "success"
          sendback.data = returnData
          
          # On GET success, Update model data
          _this.model name, JSON.parse(returnData)  if method is "GET"
          
          # On DELETE success, Remove model
          _this.model name, null  if method is "DELETE"
          
          # Fire onsync if present
          model.onsync sendback  if model.hasOwnProperty("onsync")
          
          # Publish for any subscriptions
          _this.publish "model_" + name + "_sync", sendback

        error: (req) ->
          
          # Set sendback
          sendback.status = "error"
          sendback.data = req
          
          # Fire onsync if present
          model.onsync sendback  if model.hasOwnProperty("onsync")
          
          # Publish for any subscriptions
          _this.publish "model_" + name + "_sync", sendback
          
          # Drop error bomb
          throw new Error("Model Sync Error: [req] : " + req)

      
      # Call the ajax function
      _this.ajax syncParams

    
    ###
    @method request
    
    Allows for storing pre-set xhr requests for re-use
    
    @param {String} name The name of the xhr-request
    @param {Object} params Paramaters of the request to define (see @method ajax)
    ###
    request: (name, params) ->
      _this = this
      
      # If value is detected, set new or modify request
      if typeof params is "object" and params isnt null
        
        # Stringify objects
        _this.requests[name] =
          
          # Connection parameters
          params: params
          
          # Define call method, ex: spa.request("some_request").call(data);
          call: _this.callRequest.bind(_this, name)

        
        # Return the request for variable assignment
        return _this.requests[name]
      
      # No params supplied, return request
      return _this.requests[name]  if typeof data is "undefined"
      
      # Null specified, remove request
      delete _this.requests[name]  if _this.requests.hasOwnProperty(name)  if params is null

    
    ###
    @method callRequest
    
    Fires a stored request via ajax() method
    
    @param {String} name The name passed from the bind, or manually supplied
    @param {Object} data The data to be sent with the request
    @param {Function} [success] Optional success callback, can also be specified in request params
    @param {Function} [error] Optional error callback, can also be specified in request params
    ###
    callRequest: (name, data, success, error) ->
      _this = this
      request = {}
      param = undefined
      
      # Check for optional success and error callbacks
      success = success or false
      error = error or false
      if _this.requests.hasOwnProperty(name)
        
        # We have to loop the request's params into the new request object
        # so we don't override the requests settings
        for param of _this.requests[name].params
          request[param] = _this.requests[name].params[param]  if _this.requests[name].params.hasOwnProperty(param)
        
        # Parse any URL data
        request.url = _this.parseURL(request.url, data)
        
        # Set the data param
        request.data = data
        
        # Check for success callback
        request.success = success  if success and typeof success is "function"
        
        # Check for error callback
        request.error = error  if error and typeof error is "function"
        
        # Call the ajax request
        _this.ajax request

    
    ###
    @method parseURL
    
    Parses model's url property against data object
    
    @param {String} url The url of the model
    @param {Object} data Contents of the model
    ###
    parseURL: (url, data) ->
      url.replace /\{([^}]+)\}/g, (i, match) ->
        data[match]


    
    ###
    @method ajax
    
    Used to make AJAX calls
    
    @param {String} url URL of the resource
    @param {Object} [config] Configuration object passed into request
    
    Configuration Object:**
    
    `url`: URL of request if not specified as first argument
    
    `type`: Request method, defaults to `GET`
    
    `async`: Run request asynchronously, defaults to `TRUE`
    
    `cache`: Cache the request, defaults to `TRUE`
    
    `data`: Object or JSON data passed through request
    
    `success`: Function called on successful request
    
    `error`: Function called on failure of request
    
    `qsData`: Allows blocking (set `false`) of `data` add to URL for RESTful requests
    ###
    ajax: ->
      
      # Parent object for all parameters
      
      # Determine call structure: ajax(url, { params }); or ajax({ params });
      
      # All params passed as object
      
      # Populate xhr obj with second argument
      
      # Add first argument to xhr object as url
      
      # Parameters & Defaults
      
      # Format xhr.data & encode values
      
      # Appends data to URL
      formatURL = (data) ->
        url_split = xhr.url.split("?")
        if url_split.length isnt 1
          xhr.url += "&" + data
        else
          xhr.url += "?" + data
      xhr = {}
      if arguments_.length is 1
        xhr = arguments_[0]
      else
        xhr = arguments_[1]
        xhr.url = arguments_[0]
      xhr.request = false
      xhr.type = xhr.type or "GET"
      xhr.data = xhr.data or null
      if xhr.qsData or not xhr.hasOwnProperty("qsData")
        xhr.qsData = true
      else
        xhr.qsData = false
      if xhr.cache or not xhr.hasOwnProperty("cache")
        xhr.cache = true
      else
        xhr.cache = false
      if xhr.async or not xhr.hasOwnProperty("async")
        xhr.async = true
      else
        xhr.async = false
      if xhr.success and typeof xhr.success is "function"
        xhr.success = xhr.success
      else
        xhr.success = false
      if xhr.error and typeof xhr.error is "function"
        xhr.error = xhr.error
      else
        xhr.error = false
      if xhr.data
        param_count = 0
        name = undefined
        value = undefined
        tmp_data = xhr.data
        for param of tmp_data
          if tmp_data.hasOwnProperty(param)
            name = encodeURIComponent(param)
            value = encodeURIComponent(tmp_data[param])
            if param_count is 0
              xhr.data = name + "=" + value
            else
              xhr.data += "&" + name + "=" + value
            param_count++
        xhr.data = xhr.data
      
      # Handle xhr.data on GET request type
      formatURL xhr.data  if xhr.data and xhr.type.toUpperCase() is "GET" and xhr.qsData
      
      # Check cache parameter, set URL param
      formatURL new Date().getTime()  unless xhr.cache
      
      # Establish request
      if window.XMLHttpRequest
        
        # Modern non-IE
        xhr.request = new XMLHttpRequest()
      else if window.ActiveXObject
        
        # Internet Explorer
        xhr.request = new ActiveXObject("Microsoft.XMLHTTP")
      else
        
        # No request object, break
        return false
      
      # Monitor ReadyState
      xhr.request.onreadystatechange = ->
        responseText = undefined
        if xhr.request.readyState is 4
          if xhr.request.status is 200
            if xhr.success
              
              # Check for JSON responseText, return object
              try
                responseText = JSON.parse(xhr.request.responseText)
              catch e
                responseText = xhr.request.responseText
              
              # Returns responseText and request object
              xhr.success responseText, xhr.request
          else
            
            # Returns request object
            xhr.error xhr.request  if xhr.error

      
      # Open Http Request connection
      xhr.request.open xhr.type, xhr.url, xhr.async
      
      # Set request header for POST
      xhr.request.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"  if xhr.type.toUpperCase() is "POST" or xhr.type.toUpperCase() is "PUT"
      
      # Send data
      xhr.request.send xhr.data

    
    ###
    @method store
    
    LocalStorage with polyfill support via cookies
    
    @param {String} key The key or identifier for the store
    @param {String|Object} [value] Contents of the store, blank to return, 'null' to clear
    
    Specify a string/object value to `set`, none to `get`, and 'null' to `clear`
    ###
    store: (key, value) ->
      _this = this
      lsSupport = false
      data = undefined
      
      # Check for native support
      lsSupport = true  if localStorage
      
      # If value is detected, set new or modify store
      if typeof value isnt "undefined" and value isnt null
        
        # Stringify objects
        value = JSON.stringify(value)  if typeof value is "object"
        
        # Add to / modify storage
        if lsSupport # Native support
          localStorage.setItem key, value
        else # Use Cookie
          _this.createCookie key, value, 30
      
      # No value supplied, return value
      if typeof value is "undefined"
        
        # Get value
        if lsSupport # Native support
          data = localStorage.getItem(key)
        else # Use cookie
          data = _this.readCookie(key)
        
        # Try to parse JSON...
        try
          data = JSON.parse(data)
        catch e
          data = data
        return data
      
      # Null specified, remove store
      if value is null
        if lsSupport # Native support
          localStorage.removeItem key
        else # Use cookie
          _this.createCookie key, "", -1

    
    ###
    @method createCookie
    
    Creates new cookie or removes cookie with negative expiration
    
    @param {String} key The key or identifier for the store
    @param {String} value Contents of the store
    @param {Number} exp Expiration in days
    ###
    createCookie: (key, value, exp) ->
      date = new Date()
      expires = undefined
      date.setTime date.getTime() + (exp * 24 * 60 * 60 * 1000)
      expires = "; expires=" + date.toGMTString()
      document.cookie = key + "=" + value + expires + "; path=/"

    
    ###
    Returns contents of cookie
    
    @param {String} key The key or identifier for the store
    @return {String} the value of the cookie
    ###
    readCookie: (key) ->
      nameEQ = key + "="
      ca = document.cookie.split(";")
      i = undefined
      max = undefined
      c = undefined
      i = 0
      max = ca.length

      while i < max
        c = ca[i]
        c = c.substring(1, c.length)  while c.charAt(0) is " "
        return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
        i++
      null

    
    ###
    Placeholder object for pub/sub
    ###
    topics: {}
    
    ###
    ID for incrementing
    ###
    topic_id: 0
    
    ###
    @method publish
    
    Publish to a topic
    
    @param {String} topic Topic of the subscription
    @param {Object} args Array of arguments passed
    ###
    publish: (topic, args) ->
      _this = this
      return false  unless _this.topics.hasOwnProperty(topic)
      setTimeout (->
        subscribers = _this.topics[topic]
        len = undefined
        if subscribers.length
          len = subscribers.length
        else
          return false
        subscribers[len].fn args  while len--
      ), 0
      true

    
    ###
    @method subscribe
    
    Subscribes to a topic
    
    @param {String} topic Topic of the subscription
    @param {Function} fn Function to be called
    ###
    subscribe: (topic, fn) ->
      _this = this
      id = ++@topic_id
      max = undefined
      i = undefined
      
      # Create new topic
      _this.topics[topic] = []  unless _this.topics[topic]
      
      # Prevent re-subscribe issues (common on route-reload)
      i = 0
      max = _this.topics[topic].length

      while i < max
        return _this.topics[topic][i].id  if _this.topics[topic][i].fn.toString() is fn.toString()
        i++
      _this.topics[topic].push
        id: id
        fn: fn

      id

    
    ###
    @method unsubscribe
    
    Unsubscribes from a topic
    
    @param {String} token Token of the subscription
    ###
    unsubscribe: (token) ->
      _this = this
      topic = undefined
      i = undefined
      max = undefined
      for topic of _this.topics
        if _this.topics.hasOwnProperty(topic)
          i = 0
          max = _this.topics[topic].length

          while i < max
            if _this.topics[topic][i].id is token
              _this.topics[topic].splice i, 1
              return token
            i++
      false

    
    ###
    @method polyfill_bind
    
    Polyfill for .bind()
    ###
    polyfill_bind: ->
      Function::bind = (obj) ->
        
        # closest thing possible to the ECMAScript 5 internal IsCallable function
        throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable")  if typeof this isnt "function"
        slice = [].slice
        args = slice.call(arguments_, 1)
        self = this
        nop = ->

        bound = ->
          self.apply (if this instanceof nop then this else (obj or {})), args.concat(slice.call(arguments_))

        bound:: = @::
        bound

    
    ###
    Helper function that executes a callback function on each module.el
    @method foreEachEl
    @param {function} callback
    ###
    forEachEl: (callback) ->
      if typeof callback is "function"
        index = -1
        max = @el.length
        return  if callback(index, @el[index], @el) is false  while ++index < max
      else
        throw new Error("Callback must be a function")

  
  # Return the framework
  spa
