window.joinRoom = ->
  window.getTime().then((t) ->
    console.log("Loaded Join Room page at time: " + t)
    return
  )
  nav = document.querySelector("nav")
  nav.style.display = 'none'
  [secretID, usrnm, sesh] = localStorage.getItem("account").split(",")
  form = document.querySelector("#joinRoomForm")
  tempKeyInput = document.querySelector("#tempKeyField")
  nicknameInput = document.querySelector("#userNicknameField")
  nicknameInput.value = usrnm
  joinRoomFromForm = (e) ->
    # prevent normal submission behavior that refreshes page
    e.preventDefault()
    tempKey = tempKeyInput.value.toLowerCase()
    if tempKeyInput.length != 6
      alert("Temporary Key must be exactly 6 alphanumeric characters")
      return
    nickname = nicknameInput.value
    roomName.value = ''
    nickname.value = ''
    peerjsChannelId = 'a' + nacl.util.encodeBase64(window.hasher(tempKey)) + 'a'
    alert("UNDER CONSTRUCTION")
    # window.runPage("list")
    return
  form.onsubmit = joinRoomFromForm
  return
