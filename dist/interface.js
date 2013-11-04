(function() {
  var Interface;

  Interface = function(name, methods) {
    var i, len, _results;
    if (arguments_.length !== 2) {
      throw new Error("Interface constructor called with " + arguments_.length + "arguments, but expected exactly 2.");
    }
    this.name = name;
    this.methods = [];
    i = 0;
    len = methods.length;
    _results = [];
    while (i < len) {
      if (typeof methods[i] !== "string") {
        throw new Error("Interface constructor expects method names to be " + "passed in as a string.");
      }
      this.methods.push(methods[i]);
      _results.push(i++);
    }
    return _results;
  };

  Interface.ensureImplements = function(object) {
    var i, j, len, method, methodsLen, _interface, _results;
    if (arguments_.length < 2) {
      throw new Error("Function Interface.ensureImplements called with " + arguments_.length + "arguments, but expected at least 2.");
    }
    i = 1;
    len = arguments_.length;
    _results = [];
    while (i < len) {
      _interface = arguments_[i];
      if (_interface.constructor !== Interface) {
        throw new Error("Function Interface.ensureImplements expects arguments" + "two and above to be instances of Interface.");
      }
      j = 0;
      methodsLen = _interface.methods.length;
      while (j < methodsLen) {
        method = _interface.methods[j];
        if (!object[method] || typeof object[method] !== "function") {
          throw new Error("Function Interface.ensureImplements: object " + "does not implement the " + _interface.name + " interface. Method " + method + " was not found.");
        }
        j++;
      }
      _results.push(i++);
    }
    return _results;
  };

}).call(this);

/*
//@ sourceMappingURL=interface.js.map
*/