/*
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
*/


/*
spa.js Framework
*/


(function() {
  define(function() {
    "use strict";
    /*
    The main spa object
    @type {Object}
    */

    var spa;
    spa = {
      /*
      Container for all routes
      @type {Object}
      */

      routes: {},
      /*
      Container for all module objects
      @type {Object}
      */

      scope: {},
      /*
      Conatiner for all dependencies
      @type {Object}
      */

      dependencies: {},
      /*
      Container for all models
      @type {Object}
      */

      models: {},
      /*
      Container for all defined xhr requests
      @type {Object}
      */

      requests: {},
      /*
      @method init
      
      Adds module to spa object, sets up core properties and initializes router
      */

      init: function() {
        var i, max, module, _this;
        module = void 0;
        _this = this;
        i = void 0;
        max = void 0;
        window.spa = this;
        require(this.modules, function() {
          i = 0;
          max = arguments_.length;
          while (i < max) {
            module = _this.modules[i].split("/").pop();
            _this.scope[module] = arguments_[i];
            _this.scope[module].mid = module;
            _this.scope[module].el = document.querySelectorAll("[data-view='" + module + "']");
            if (typeof jQuery !== "undefined") {
              _this.scope[module].$el = jQuery("[data-view='" + module + "']");
            }
            _this.scope[module].forEachEl = _this.forEachEl;
            i++;
          }
          return _this.router();
        });
        if (!Function.prototype.bind) {
          return this.polyfill_bind();
        }
      },
      /*
      @method router
      
      Sets up Routing Table, binds and loads Routes
      */

      router: function() {
        var cur_route, module, route, _this;
        cur_route = window.location.hash;
        _this = this;
        module = void 0;
        route = void 0;
        for (module in this.scope) {
          if (this.scope.hasOwnProperty(module)) {
            for (route in this.scope[module].routes) {
              if (!this.routes.hasOwnProperty(route)) {
                this.routes[route] = [[module, this.scope[module].routes[route]]];
              } else {
                this.routes[route].push([module, this.scope[module].routes[route]]);
              }
            }
          }
        }
        this.loadUrl(cur_route);
        return window.onhashchange = function() {
          return _this.loadUrl(window.location.hash);
        };
      },
      /*
      @method loadUrl
      
      Checks to verify that current route matches a module's route, passes it to the processor() and hides all modules that don't need to be rendered
      
      @param {String} fragment The current hash
      */

      loadUrl: function(fragment) {
        var bits, el_lock, i, max, module_name, qs_data, querystring, route, url_data, _i, _max, _results, _this;
        _this = this;
        querystring = false;
        url_data = {};
        qs_data = void 0;
        el_lock = void 0;
        module_name = void 0;
        route = void 0;
        i = void 0;
        max = void 0;
        _i = void 0;
        _max = void 0;
        bits = void 0;
        fragment = fragment.replace("#!/", "");
        if (fragment.substr(-1) === "/") {
          fragment = fragment.substr(0, fragment.length - 1);
        }
        fragment = fragment.split("?");
        if (fragment[1]) {
          querystring = fragment[1];
        }
        fragment = fragment[0].split("/");
        if (fragment.length > 0) {
          i = 1;
          max = fragment.length;
          while (i < max) {
            url_data[i - 1] = fragment[i];
            i++;
          }
        }
        if (querystring) {
          qs_data = querystring.split("&");
          i = 0;
          max = qs_data.length;
          while (i < max) {
            bits = qs_data[i].split("=");
            url_data[bits[0]] = bits[1];
            i++;
          }
        }
        _this.current_route = fragment[0];
        _this.url_data = url_data;
        _results = [];
        for (route in _this.routes) {
          if (_this.routes.hasOwnProperty(route)) {
            _i = 0;
            _max = _this.routes[route].length;
            _results.push((function() {
              var _results1;
              _results1 = [];
              while (_i < _max) {
                module_name = _this.routes[route][_i][0];
                if (fragment[0] === route || route === "*") {
                  if (el_lock !== module_name) {
                    el_lock = module_name;
                    _this.processor(module_name, _this.routes[route][_i][1], url_data);
                  }
                } else {
                  _this.unrender(module_name);
                }
                _results1.push(_i++);
              }
              return _results1;
            })());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      },
      /*
      @method processor
      
      Handles processing of the module, loads template, fires dependency loader then the route event
      
      @param {Object} module The module object to be used.
      @param {Function} route_fn The return function from the route.
      @param {Object} url_data The data from any url query strings
      */

      processor: function(module, route_fn, url_data) {
        var scope, _this;
        scope = this.scope[module];
        _this = this;
        scope.loaded = true;
        if (!scope.hasOwnProperty("template")) {
          return _this.ajax({
            url: "templates/" + scope.mid + ".tpl",
            type: "GET",
            success: function(data) {
              scope.template = data;
              return _this.loadDependencies(scope, function() {
                return scope[route_fn](url_data);
              });
            },
            error: function() {
              return console.log("Could not load template for " + scope.mid);
            }
          });
        } else {
          return _this.loadDependencies(scope, function() {
            return scope[route_fn](url_data);
          });
        }
      },
      /*
      @method loadDependencies
      
      Checks for & loads any dependencies before calling the route's function
      
      @param {Object} scope The module object to be used.
      @param {Function} callback Function to execute when all deps are loaded
      */

      loadDependencies: function(scope, callback) {
        var arr_dep_name, arr_dep_src, dep, dep_name, dep_src, i, max, _this;
        _this = this;
        i = void 0;
        max = void 0;
        dep = void 0;
        dep_name = void 0;
        dep_src = void 0;
        arr_dep_name = [];
        arr_dep_src = [];
        if (scope.hasOwnProperty("dependencies")) {
          for (dep in scope.dependencies) {
            if (scope.dependencies.hasOwnProperty(dep)) {
              dep_name = dep;
              dep_src = scope.dependencies[dep];
              if (_this.dependencies.hasOwnProperty(dep_src)) {
                scope[dep_name] = _this.dependencies[dep_src];
              } else {
                arr_dep_name.push(dep_name);
                arr_dep_src.push(dep_src);
              }
            }
          }
          return require(arr_dep_src, function() {
            i = 0;
            max = arguments_.length;
            while (i < max) {
              scope[arr_dep_name[i]] = arguments_[i];
              _this.dependencies[arr_dep_src[i]] = arguments_[i];
              i++;
            }
            if (callback && typeof callback === "function") {
              return callback(scope);
            }
          });
        } else {
          if (callback && typeof callback === "function") {
            return callback(scope);
          }
        }
      },
      /*
      @method render
      
      Renders a module's template onto the screen
      
      @param {Object} scope The module object to be used.
      @param {Object} [data] Any data to be rendered onto the template.
      */

      render: function(scope, data) {
        var el, i, max, rendered, template, templateRender, _this;
        _this = this;
        template = scope.template;
        templateRender = void 0;
        rendered = void 0;
        max = void 0;
        el = void 0;
        i = void 0;
        templateRender = function(i, match) {
          return data[match];
        };
        max = scope.el.length;
        i = 0;
        while (i < max) {
          el = scope.el[i];
          rendered = template.replace(/\{\{([^}]+)\}\}/g, templateRender);
          el.innerHTML = rendered;
          el.style.display = "block";
          i++;
        }
        return _this.delegateEvents(scope.events, scope);
      },
      /*
      @method unrender
      
      Removes unused modules' content from DOM and sets display to none
      
      @param {String} module_name The name of the module to unrender
      */

      unrender: function(module_name) {
        var el, index, max, _results;
        index = void 0;
        el = void 0;
        max = void 0;
        el = document.querySelectorAll("[data-view='" + module_name + "']");
        index = 0;
        max = el.length;
        _results = [];
        while (index < max) {
          el[index].innerHTML = "";
          el[index].style.display = "none";
          _results.push(index++);
        }
        return _results;
      },
      /*
      @method access
      
      Proxy function for accessing other modules and their dependencies
      
      @param {Object} module Name of the module to access
      @param {Function} callback The function to fire once access is complete
      */

      access: function(module, callback) {
        var scope, _this;
        _this = this;
        scope = this.scope[module];
        if (!scope.hasOwnProperty("loaded")) {
          return _this.loadDependencies(scope, function(scope) {
            scope.loaded = true;
            if (callback && typeof callback === "function") {
              return callback(scope);
            }
          });
        } else {
          if (callback && typeof callback === "function") {
            return callback(scope);
          }
        }
      },
      /*
      @method navigate
      
      Responsible for updating the history hash, and changing the URL
      
      @param  {String} fragment The location to be loaded
      @return {Boolean}
      */

      navigate: function(fragment) {
        var location, root, url, _this;
        location = window.location;
        root = location.pathname.replace(/[^\/]$/, "$&");
        _this = this;
        url = void 0;
        if (fragment.length) {
          url = root + location.search + "#!/" + fragment;
        } else {
          url = root + location.search;
        }
        if (history.pushState) {
          history.pushState(null, document.title, url);
          _this.loadUrl(fragment);
        } else {
          location.replace(root + url);
        }
        return true;
      },
      /*
      @method delegateEvents
      
      Binds callbacks for a module's events object
      
      @param {Object} events Events to be watched for
      @param {Object} scope The current module
      */

      delegateEvents: function(events, scope) {
        var delegateEventSplitter, event_name, i, key, match, max, method, nodes, selector, _results, _this;
        delegateEventSplitter = /^(\S+)\s*(.*)$/;
        _this = this;
        method = void 0;
        match = void 0;
        event_name = void 0;
        selector = void 0;
        nodes = void 0;
        key = void 0;
        max = void 0;
        i = void 0;
        if (!events) {
          return;
        }
        _results = [];
        for (key in events) {
          if (events.hasOwnProperty(key)) {
            method = events[key];
            match = key.match(delegateEventSplitter);
            event_name = match[1];
            selector = match[2];
            nodes = document.querySelectorAll("[data-view='" + scope.mid + "'] " + selector);
            i = 0;
            max = nodes.length;
            _results.push((function() {
              var _results1;
              _results1 = [];
              while (i < max) {
                _this.bindEvent(nodes[i], event_name, scope[method].bind(scope), true);
                _results1.push(i++);
              }
              return _results1;
            })());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      },
      /*
      @method bindEvent
      
      Used to bind events to DOM objects
      
      @param {Object} el Element on which to attach event
      @param {String} evt Event name
      @param {Function} fn Function to be called
      @param {Boolean} [pdef] Boolean to preventDefault
      */

      bindEvent: function(el, evt, fn, pdef) {
        pdef = pdef || false;
        if (el.addEventListener) {
          return el.addEventListener(evt, (function(event) {
            if (pdef) {
              if (event.preventDefault) {
                event.preventDefault();
              } else {
                event.returnValue = false;
              }
            }
            return fn(event);
          }), false);
        } else {
          return el.attachEvent("on" + evt, function(event) {
            if (pdef) {
              if (event.preventDefault) {
                event.preventDefault();
              } else {
                event.returnValue = false;
              }
            }
            return fn(event);
          });
        }
      },
      /*
      @method model
      
      Allows for local API model create, read, and delete
      
      @param {String} name The name of the model
      @param {Object} [data] Contents of the model, blank to return, 'null' to clear
      
      Specify a object value to `set`, none to `get`, and 'null' to `clear`
      */

      model: function() {
        var model, name, params, _this;
        _this = this;
        name = void 0;
        model = void 0;
        params = void 0;
        if (typeof arguments_[0] === "object") {
          params = arguments_[0];
          params.url = params.url || false;
          params.onchange = params.onchange || false;
          if (typeof params.name === "string" && params.name !== "") {
            _this.models[params.name] = {
              data: params.data,
              get: _this.sync.bind(_this, params.name, "GET"),
              put: _this.sync.bind(_this, params.name, "PUT"),
              post: _this.sync.bind(_this, params.name, "POST"),
              "delete": _this.sync.bind(_this, params.name, "DELETE")
            };
            if (params.url) {
              _this.models[params.name].url = params.url;
            }
            if (params.onchange) {
              _this.models[params.name].onchange = params.onchange;
            }
            if (params.onsync) {
              _this.models[params.name].onsync = params.onsync;
            }
            return _this.models[params.name];
          } else {
            throw new Error("Cannot create a null model");
          }
        } else if (arguments_.length === 2) {
          name = arguments_[0];
          model = _this.models[name];
          if (typeof arguments_[1] === "object" && arguments_[1] !== null) {
            model.data = arguments_[1];
            if (model.hasOwnProperty("onchange")) {
              model.onchange(model.data);
            }
            return _this.publish("model_" + name + "_change", model.data);
          } else {
            return delete _this.models[name];
          }
        } else {
          name = arguments_[0];
          model = _this.models[name];
          return model;
        }
      },
      /*
      @method sync
      
      Gets bound to models, used to access API
      
      @param {String} name Name of the model
      @param {String} method RESTful request method
      */

      sync: function(name, method) {
        var data, model, sendback, syncParams, url, _this;
        model = this.models[name];
        sendback = {};
        _this = this;
        url = this.parseURL(model.url, model.data);
        data = model.data;
        syncParams = {
          url: url,
          type: method,
          data: data,
          qsData: false,
          success: function(returnData) {
            sendback.status = "success";
            sendback.data = returnData;
            if (method === "GET") {
              _this.model(name, JSON.parse(returnData));
            }
            if (method === "DELETE") {
              _this.model(name, null);
            }
            if (model.hasOwnProperty("onsync")) {
              model.onsync(sendback);
            }
            return _this.publish("model_" + name + "_sync", sendback);
          },
          error: function(req) {
            sendback.status = "error";
            sendback.data = req;
            if (model.hasOwnProperty("onsync")) {
              model.onsync(sendback);
            }
            _this.publish("model_" + name + "_sync", sendback);
            throw new Error("Model Sync Error: [req] : " + req);
          }
        };
        return _this.ajax(syncParams);
      },
      /*
      @method request
      
      Allows for storing pre-set xhr requests for re-use
      
      @param {String} name The name of the xhr-request
      @param {Object} params Paramaters of the request to define (see @method ajax)
      */

      request: function(name, params) {
        var _this;
        _this = this;
        if (typeof params === "object" && params !== null) {
          _this.requests[name] = {
            params: params,
            call: _this.callRequest.bind(_this, name)
          };
          return _this.requests[name];
        }
        if (typeof data === "undefined") {
          return _this.requests[name];
        }
        if (params === null ? _this.requests.hasOwnProperty(name) : void 0) {
          return delete _this.requests[name];
        }
      },
      /*
      @method callRequest
      
      Fires a stored request via ajax() method
      
      @param {String} name The name passed from the bind, or manually supplied
      @param {Object} data The data to be sent with the request
      @param {Function} [success] Optional success callback, can also be specified in request params
      @param {Function} [error] Optional error callback, can also be specified in request params
      */

      callRequest: function(name, data, success, error) {
        var param, request, _this;
        _this = this;
        request = {};
        param = void 0;
        success = success || false;
        error = error || false;
        if (_this.requests.hasOwnProperty(name)) {
          for (param in _this.requests[name].params) {
            if (_this.requests[name].params.hasOwnProperty(param)) {
              request[param] = _this.requests[name].params[param];
            }
          }
          request.url = _this.parseURL(request.url, data);
          request.data = data;
          if (success && typeof success === "function") {
            request.success = success;
          }
          if (error && typeof error === "function") {
            request.error = error;
          }
          return _this.ajax(request);
        }
      },
      /*
      @method parseURL
      
      Parses model's url property against data object
      
      @param {String} url The url of the model
      @param {Object} data Contents of the model
      */

      parseURL: function(url, data) {
        return url.replace(/\{([^}]+)\}/g, function(i, match) {
          return data[match];
        });
      },
      /*
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
      */

      ajax: function() {
        var formatURL, name, param, param_count, tmp_data, value, xhr;
        formatURL = function(data) {
          var url_split;
          url_split = xhr.url.split("?");
          if (url_split.length !== 1) {
            return xhr.url += "&" + data;
          } else {
            return xhr.url += "?" + data;
          }
        };
        xhr = {};
        if (arguments_.length === 1) {
          xhr = arguments_[0];
        } else {
          xhr = arguments_[1];
          xhr.url = arguments_[0];
        }
        xhr.request = false;
        xhr.type = xhr.type || "GET";
        xhr.data = xhr.data || null;
        if (xhr.qsData || !xhr.hasOwnProperty("qsData")) {
          xhr.qsData = true;
        } else {
          xhr.qsData = false;
        }
        if (xhr.cache || !xhr.hasOwnProperty("cache")) {
          xhr.cache = true;
        } else {
          xhr.cache = false;
        }
        if (xhr.async || !xhr.hasOwnProperty("async")) {
          xhr.async = true;
        } else {
          xhr.async = false;
        }
        if (xhr.success && typeof xhr.success === "function") {
          xhr.success = xhr.success;
        } else {
          xhr.success = false;
        }
        if (xhr.error && typeof xhr.error === "function") {
          xhr.error = xhr.error;
        } else {
          xhr.error = false;
        }
        if (xhr.data) {
          param_count = 0;
          name = void 0;
          value = void 0;
          tmp_data = xhr.data;
          for (param in tmp_data) {
            if (tmp_data.hasOwnProperty(param)) {
              name = encodeURIComponent(param);
              value = encodeURIComponent(tmp_data[param]);
              if (param_count === 0) {
                xhr.data = name + "=" + value;
              } else {
                xhr.data += "&" + name + "=" + value;
              }
              param_count++;
            }
          }
          xhr.data = xhr.data;
        }
        if (xhr.data && xhr.type.toUpperCase() === "GET" && xhr.qsData) {
          formatURL(xhr.data);
        }
        if (!xhr.cache) {
          formatURL(new Date().getTime());
        }
        if (window.XMLHttpRequest) {
          xhr.request = new XMLHttpRequest();
        } else if (window.ActiveXObject) {
          xhr.request = new ActiveXObject("Microsoft.XMLHTTP");
        } else {
          return false;
        }
        xhr.request.onreadystatechange = function() {
          var e, responseText;
          responseText = void 0;
          if (xhr.request.readyState === 4) {
            if (xhr.request.status === 200) {
              if (xhr.success) {
                try {
                  responseText = JSON.parse(xhr.request.responseText);
                } catch (_error) {
                  e = _error;
                  responseText = xhr.request.responseText;
                }
                return xhr.success(responseText, xhr.request);
              }
            } else {
              if (xhr.error) {
                return xhr.error(xhr.request);
              }
            }
          }
        };
        xhr.request.open(xhr.type, xhr.url, xhr.async);
        if (xhr.type.toUpperCase() === "POST" || xhr.type.toUpperCase() === "PUT") {
          xhr.request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        }
        return xhr.request.send(xhr.data);
      },
      /*
      @method store
      
      LocalStorage with polyfill support via cookies
      
      @param {String} key The key or identifier for the store
      @param {String|Object} [value] Contents of the store, blank to return, 'null' to clear
      
      Specify a string/object value to `set`, none to `get`, and 'null' to `clear`
      */

      store: function(key, value) {
        var data, e, lsSupport, _this;
        _this = this;
        lsSupport = false;
        data = void 0;
        if (localStorage) {
          lsSupport = true;
        }
        if (typeof value !== "undefined" && value !== null) {
          if (typeof value === "object") {
            value = JSON.stringify(value);
          }
          if (lsSupport) {
            localStorage.setItem(key, value);
          } else {
            _this.createCookie(key, value, 30);
          }
        }
        if (typeof value === "undefined") {
          if (lsSupport) {
            data = localStorage.getItem(key);
          } else {
            data = _this.readCookie(key);
          }
          try {
            data = JSON.parse(data);
          } catch (_error) {
            e = _error;
            data = data;
          }
          return data;
        }
        if (value === null) {
          if (lsSupport) {
            return localStorage.removeItem(key);
          } else {
            return _this.createCookie(key, "", -1);
          }
        }
      },
      /*
      @method createCookie
      
      Creates new cookie or removes cookie with negative expiration
      
      @param {String} key The key or identifier for the store
      @param {String} value Contents of the store
      @param {Number} exp Expiration in days
      */

      createCookie: function(key, value, exp) {
        var date, expires;
        date = new Date();
        expires = void 0;
        date.setTime(date.getTime() + (exp * 24 * 60 * 60 * 1000));
        expires = "; expires=" + date.toGMTString();
        return document.cookie = key + "=" + value + expires + "; path=/";
      },
      /*
      Returns contents of cookie
      
      @param {String} key The key or identifier for the store
      @return {String} the value of the cookie
      */

      readCookie: function(key) {
        var c, ca, i, max, nameEQ;
        nameEQ = key + "=";
        ca = document.cookie.split(";");
        i = void 0;
        max = void 0;
        c = void 0;
        i = 0;
        max = ca.length;
        while (i < max) {
          c = ca[i];
          while (c.charAt(0) === " ") {
            c = c.substring(1, c.length);
          }
          if (c.indexOf(nameEQ) === 0) {
            return c.substring(nameEQ.length, c.length);
          }
          i++;
        }
        return null;
      },
      /*
      Placeholder object for pub/sub
      */

      topics: {},
      /*
      ID for incrementing
      */

      topic_id: 0,
      /*
      @method publish
      
      Publish to a topic
      
      @param {String} topic Topic of the subscription
      @param {Object} args Array of arguments passed
      */

      publish: function(topic, args) {
        var _this;
        _this = this;
        if (!_this.topics.hasOwnProperty(topic)) {
          return false;
        }
        setTimeout((function() {
          var len, subscribers, _results;
          subscribers = _this.topics[topic];
          len = void 0;
          if (subscribers.length) {
            len = subscribers.length;
          } else {
            return false;
          }
          _results = [];
          while (len--) {
            _results.push(subscribers[len].fn(args));
          }
          return _results;
        }), 0);
        return true;
      },
      /*
      @method subscribe
      
      Subscribes to a topic
      
      @param {String} topic Topic of the subscription
      @param {Function} fn Function to be called
      */

      subscribe: function(topic, fn) {
        var i, id, max, _this;
        _this = this;
        id = ++this.topic_id;
        max = void 0;
        i = void 0;
        if (!_this.topics[topic]) {
          _this.topics[topic] = [];
        }
        i = 0;
        max = _this.topics[topic].length;
        while (i < max) {
          if (_this.topics[topic][i].fn.toString() === fn.toString()) {
            return _this.topics[topic][i].id;
          }
          i++;
        }
        _this.topics[topic].push({
          id: id,
          fn: fn
        });
        return id;
      },
      /*
      @method unsubscribe
      
      Unsubscribes from a topic
      
      @param {String} token Token of the subscription
      */

      unsubscribe: function(token) {
        var i, max, topic, _this;
        _this = this;
        topic = void 0;
        i = void 0;
        max = void 0;
        for (topic in _this.topics) {
          if (_this.topics.hasOwnProperty(topic)) {
            i = 0;
            max = _this.topics[topic].length;
            while (i < max) {
              if (_this.topics[topic][i].id === token) {
                _this.topics[topic].splice(i, 1);
                return token;
              }
              i++;
            }
          }
        }
        return false;
      },
      /*
      @method polyfill_bind
      
      Polyfill for .bind()
      */

      polyfill_bind: function() {
        return Function.prototype.bind = function(obj) {
          var args, bound, nop, self, slice;
          if (typeof this !== "function") {
            throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
          }
          slice = [].slice;
          args = slice.call(arguments_, 1);
          self = this;
          nop = function() {};
          bound = function() {
            return self.apply((this instanceof nop ? this : obj || {}), args.concat(slice.call(arguments_)));
          };
          bound.prototype = this.prototype;
          return bound;
        };
      },
      /*
      Helper function that executes a callback function on each module.el
      @method foreEachEl
      @param {function} callback
      */

      forEachEl: function(callback) {
        var index, max;
        if (typeof callback === "function") {
          index = -1;
          max = this.el.length;
          if ((function() {
            var _results;
            _results = [];
            while (++index < max) {
              _results.push(callback(index, this.el[index], this.el) === false);
            }
            return _results;
          }).call(this)) {

          }
        } else {
          throw new Error("Callback must be a function");
        }
      }
    };
    return spa;
  });

}).call(this);
