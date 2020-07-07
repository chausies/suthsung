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

window.getStamp = ->
  # reverse string
  uniqueTag = Math.floor(Math.random()*100000).toString()[0..4]
  st = (await window.getTime()).toString()
  return '0'.repeat(20-st.length) + st + uniqueTag


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

pageNames = ["signin", "list", "room", "newRoom", "joinRoom", "settings"]

window.pages = {}
for pageName in pageNames
  window.pages[pageName] = fetch('/html/' + pageName + '.html')
    .then((resp) -> return resp.text())

window.runPage = (pageName, arg) ->
  document.getElementById("mainContent").innerHTML = await window.pages[pageName]
  switch pageName
    when "signin" then await window.signin()
    when "settings" then await window.settings()
    when "newRoom" then await window.newRoom()
    when "joinRoom" then await window.joinRoom()
    when "room" then await window.room(arg)
    else
      await window.list()
  return

window.goToPage = (dict) ->
  if !dict
    loc = window.getParam("loc")
    # Go to correct page specified by url params
    if (loc!="signin") and (not localStorage.getItem("account"))
      window.goToPage({loc: "signin"})
      return
    else if (not loc) or (not (loc in pageNames))
      window.goToPage({loc: "list"})
      return
    else
      arg = null
      if loc in ["room"]
        arg = window.getParam("id")
      await window.runPage(loc, arg)
      return
  else
    loc = dict.loc
    u = new URL(window.location.href)
    for k, v of dict
      u.searchParams.set(k, v)
    window.location.href = u.href
    return

window.onload = ->
  window.goToPage()
  return
