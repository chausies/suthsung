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

window.hasher = (strs) ->
  # Hashes an array of strs, or a single str
  if Array.isArray(strs)
    return hasher(xor(hasher(strs[1..]), hasher(salts[0])))
  uint8arr = strToUint(strs)
  return sha(xor(sha(uint8arr), window.SALT))

window.pswdUsrnmToHash = (pswd, usrnm) ->
  # Takes a password and username string and returns a secretKey
  pswdHash = window.hasher(pswd)
  slt = window.hasher(usrnm)
  b = bcrypt.hash(pswdHash, slt, 12)
  seed = xor(pswdHash, Uint8Array.from(b))
  return nacl.util.encodeBase64(seed)

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
  document.getElementById("mainContent").innerHTML = await window.pages[pageName]
  switch pageName
    when "signin" then window.signin()
    when "settings" then window.settings()
    when "room" then window.room(arg)
    else
      window.list()


window.goToPage = ->
  # Go to correct page specified by url params
  loc = window.getParam("loc")
  if not localStorage.getItem("account")
    goTo = "signin"
  else if not loc
    goTo = "list"
  else if loc in ["signin", "settings", "room", "list"]
    goTo = loc
  else
    goTo = "list"
  window.runPage(goTo)

window.onload = ->
  window.goToPage()
