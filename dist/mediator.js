(function() {
  var mediator;

  mediator = (function() {
    var publish, subscribe;

    function mediator() {}

    subscribe = function(channel, fn) {
      if (!mediator.channels[channel]) {
        mediator.channels[channel] = [];
      }
      mediator.channels[channel].push({
        context: this,
        callback: fn
      });
      return this;
    };

    publish = function(channel) {
      var args, i, l, subscription;
      if (!mediator.channels[channel]) {
        return false;
      }
      args = Array.prototype.slice.call(arguments_, 1);
      i = 0;
      l = mediator.channels[channel].length;
      while (i < l) {
        subscription = mediator.channels[channel][i];
        subscription.callback.apply(subscription.context, args);
        i++;
      }
      return this;
    };

    mediator.prototype.channels = {};

    mediator.prototype.publish = publish;

    mediator.prototype.subscribe = subscribe;

    mediator.prototype.installTo = function(obj) {
      obj.subscribe = subscribe;
      return obj.publish = publish;
    };

    return mediator;

  })();

}).call(this);

/*
//@ sourceMappingURL=mediator.js.map
*/