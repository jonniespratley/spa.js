class mediator
  subscribe = (channel, fn) ->
    mediator.channels[channel] = []  unless mediator.channels[channel]
    mediator.channels[channel].push
      context: this
      callback: fn

    this

  publish = (channel) ->
    return false  unless mediator.channels[channel]
    args = Array::slice.call(arguments_, 1)
    i = 0
    l = mediator.channels[channel].length

    while i < l
      subscription = mediator.channels[channel][i]
      subscription.callback.apply subscription.context, args
      i++
    this

  channels: {}
  publish: publish
  subscribe: subscribe
  installTo: (obj) ->
    obj.subscribe = subscribe
    obj.publish = publish
