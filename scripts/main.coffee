console.log("Starting")

window.lastTime = null
window.clientTimeOffset = null
window.getTime = ->
  clientTime = Date.now()/1000
  if (not window.lastTime) or (not window.clientTimeOffset) \
  or Math.abs(clientTime-window.lastTime)>10*60
    realTime = await fetch("https://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now")
      .then((r) -> return r.text())
      .then((st) => return parseInt(st))
    clientTime = (clientTime + (Date.now()/1000))/2
    window.clientTimeOffset = realTime - clientTime
  return window.lastTime = Math.round(clientTime + window.clientTimeOffset)

window.getTime().then((t) ->
  console.log("Current Real Unix Time is: " + t)
)

strToUint = (str) ->
  return new TextEncoder('utf-8').encode(str)

uintToStr = (uint8array) ->
  return new TextDecoder().decode(uint8array)

xor = (a1, a2) ->
  # XORs two Uint8Arrays
  if a1.length > a2.length
    r = a1[..]
    s = a2
  else
    r = a2[..]
    s = a1
  for i in [0..s.length-1]
    r[i] ^= s[i]
  return r

sha = (uint8arr) ->
  return nacl.hash(uint8arr)[..31]

window.SALT = sha(strToUint("suthsung"))

window.hasher = (str, salts=null) ->
  if Array.isArray(salts)
    return hasher(xor(hasher(str, salts[1..]), hasher(salts[0])))
  if not salts
    uint8arr = strToUint(str)
    return sha(xor(sha(uint8arr), window.SALT))
  return hasher(xor(hasher(str), hasher(salts)))

window.getParam = (key) ->
  u = new URL(window.location.href)
  return u.searchParams.get(key)

window.setParams = (dict) ->
  u = new URL(window.location.href)
  for k, v of dict
    u.searchParams.set(k, v)
  window.history.pushState(null, null, u.href)

window.pages = {}
for pageName in ["signin", "list", "room", "settings"]
  window.pages[pageName] = fetch('/html/' + pageName + '.html')
    .then((resp) -> return resp.text())

window.runPage = (pageName, arg) ->
  window.setParams({loc: pageName})
  document.getElementById("body").innerHTML = await window.pages[pageName]
  switch pageName
    when "signin" then window.signin()
    when "list" then window.list()
    when "settings" then window.settings()
    when "room" then window.room(arg)

window.goToPage = ->
  # Go to correct page specified by url params
  goTo = "signin"
  loc = window.getParam("loc")
  if not localStorage.getItem("secretKey")
    goTo = "signin"
  else if not loc
    goTo = "list"
  else
    goTo = "loc"
  window.runPage(goTo)

window.onload = ->
  window.goToPage()
