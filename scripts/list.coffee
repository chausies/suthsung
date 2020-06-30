window.list = ->
  window.getTime().then((t) ->
    console.log("Loaded Sign In page at time: " + t)
    console.log("list.coffee under construction at time " + t)
    return
  )
  return
