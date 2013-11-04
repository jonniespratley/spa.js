(function() {
  var pubsub;

  pubsub = (function() {
    var subUid, topics;

    function pubsub() {}

    topics = {};

    subUid = -1;

    pubsub.publish = function(topic, args) {
      var len, subscribers;
      if (!topics[topic]) {
        return false;
      }
      subscribers = topics[topic];
      len = (subscribers ? subscribers.length : 0);
      while (len--) {
        subscribers[len].func(topic, args);
      }
      return this;
    };

    pubsub.subscribe = function(topic, func) {
      var token;
      if (!topics[topic]) {
        topics[topic] = [];
      }
      token = (++subUid).toString();
      topics[topic].push({
        token: token,
        func: func
      });
      return token;
    };

    pubsub.unsubscribe = function(token) {
      var i, j, m;
      for (m in topics) {
        if (topics[m]) {
          i = 0;
          j = topics[m].length;
          while (i < j) {
            if (topics[m][i].token === token) {
              topics[m].splice(i, 1);
              return token;
            }
            i++;
          }
        }
      }
      return this;
    };

    return pubsub;

  })();

}).call(this);

/*
//@ sourceMappingURL=pubsub.js.map
*/