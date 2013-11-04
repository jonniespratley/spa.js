
class pubsub
  topics = {}
  subUid = -1
  
  # Publish or broadcast events of interest
  # with a specific topic name and arguments
  # such as the data to pass along
  @publish = (topic, args) ->
    return false  unless topics[topic]
    subscribers = topics[topic]
    len = (if subscribers then subscribers.length else 0)
    subscribers[len].func topic, args  while len--
    this

  
  # Subscribe to events of interest
  # with a specific topic name and a
  # callback function, to be executed
  # when the topic/event is observed
  @subscribe = (topic, func) ->
    topics[topic] = []  unless topics[topic]
    token = (++subUid).toString()
    topics[topic].push
      token: token
      func: func

    token

  
  # Unsubscribe from a specific
  # topic, based on a tokenized reference
  # to the subscription
  @unsubscribe = (token) ->
    for m of topics
      if topics[m]
        i = 0
        j = topics[m].length

        while i < j
          if topics[m][i].token is token
            topics[m].splice i, 1
            return token
          i++
    this
