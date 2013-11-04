(function() {
  var Singleton;

  Singleton = (function() {
    var init, instantiated;
    init = function() {
      return {
        publicMethod: function() {
          return console.log("hello world");
        },
        publicProperty: "test"
      };
    };
    instantiated = void 0;
    return {
      getInstance: function() {
        if (!instantiated) {
          instantiated = init();
        }
        return instantiated;
      }
    };
  })();

  Singleton.getInstance().publicMethod();

}).call(this);

/*
//@ sourceMappingURL=singleton.js.map
*/