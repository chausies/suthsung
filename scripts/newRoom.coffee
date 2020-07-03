window.newRoom = ->
  window.getTime().then((t) ->
    console.log("Loaded New Room page at time: " + t)
    return
  )
  nav = document.querySelector("#navBar")
  nav.style.display = 'none'
  [secretID, usrnm, sesh] = localStorage.getItem("account").split(",")
  form = document.querySelector("#newRoomForm")
  roomNameInput = document.querySelector("#roomNameField")
  nicknameInput = document.querySelector("#userNicknameField")
  nicknameInput.value = usrnm
  createRoomFromForm = (e) ->
    # prevent normal submission behavior that refreshes page
    e.preventDefault()
    roomName = roomNameInput.value
    roomName.value = ''
    nickname = nicknameInput.value
    nickname.value = ''
    roomId = nacl.util.encodeBase64(
      crypto.getRandomValues(new Uint8Array(16)) # Random 128bit ID
    )
    alert("UNDER CONSTRUCTION")
    # window.goToPage({loc: "room", id: "placeholder"})
    return
  form.onsubmit = createRoomFromForm
  return
