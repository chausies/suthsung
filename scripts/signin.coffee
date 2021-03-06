window.signin = ->
  window.getTime().then((t) ->
    console.log("Loaded Sign In page at time: " + t)
    return
  )
  nav = document.querySelector("#navBar")
  nav.style.display = 'none'
  form = document.querySelector("#signInForm")
  usernameInput = document.querySelector("#usernameField")
  passwordInput = document.querySelector("#passwordField")
  sessionInput = document.querySelector("#sessionField")
  signinFromForm = (e) ->
    # prevent normal submission behavior that refreshes page
    e.preventDefault()
    usrnm = usernameInput.value.toLowerCase()
    usernameInput.value = ''
    pswd = passwordInput.value
    passwordInput.value = ''
    sesh = sessionInput.value.toLowerCase()
    sessionInput.value = ''
    secretId = window.pswdUsrnmToHash(pswd, usrnm)
    localforage.setItem("account", {secretId: secretId, username: usrnm, sessionName: sesh})
    .then(() ->
      window.goToPage({loc: "list"})
      return
    )
    return
  form.onsubmit = signinFromForm
  return
