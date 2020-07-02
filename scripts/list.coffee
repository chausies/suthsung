window.list = ->
  window.getTime().then((t) ->
    console.log("Loaded list page at time: " + t)
    console.log("list.coffee under construction at time " + t)
    return
  )
  nav = document.querySelector("nav")
  nav.style.display = null
  return
