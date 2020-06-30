window.signin = ->
  window.getTime().then((t) ->
    console.log("Loaded Sign In page at time: " + t)
    return
  )
  form = document.querySelector("#signInForm")
  usernameInput = document.querySelector("#usernameField")
  passwordInput = document.querySelector("#passwordField")
  sessionInput = document.querySelector("#sessionField")
  signinFromForm = (e) ->
    # prevent normal submission behavior that refreshes page
    e.preventDefault()
    usrnm = usernameInput.value
    usernameInput.value = ''
    pswd = passwordInput.value
    passwordInput.value = ''
    sesh = sessionInput.value
    sessionInput.value = ''
    keyPair = window.pswdUsrnmToKeyPair(pswd, usrnm)
    pub = nacl.util.encodeBase64(keyPair.publicKey)
    priv = nacl.util.encodeBase64(keyPair.secretKey)
    localStorage.setItem("account", [pub, priv, sesh].join(","))
    window.runPage("list")
    return
  form.onsubmit = signinFromForm
  return
