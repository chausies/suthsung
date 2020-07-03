window.room = (roomId) ->
  window.getTime().then((t) ->
    console.log("room.coffee under construction at time " + t)
    return
  )
  window.scrollTo(0, document.body.scrollHeight)
  return
