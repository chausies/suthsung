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
    # Commas are removed from username
    usrnm = usernameInput.value.toLowerCase().replaceAll(",", "")
    usernameInput.value = ''
    pswd = passwordInput.value
    passwordInput.value = ''
    sesh = sessionInput.value.toLowerCase()
    sessionInput.value = ''
    secretID = window.pswdUsrnmToHash(pswd, usrnm)
    localStorage.setItem("account", [secretID, usrnm, sesh].join(","))
    window.goToPage({loc: "list"})
    return
  form.onsubmit = signinFromForm
  return
