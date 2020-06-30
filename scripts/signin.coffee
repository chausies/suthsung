pswdUsrnmToSecretKey = (pswd, usrnm) ->
  # Takes a password and username string and returns a secretKey
  pswdHash = window.hasher(pswd)
  slt = window.hasher(usrnm)
  bcrypt.hash(pswdHash, slt, 12)

window.signin = ->
  form = document.querySelector("#signInForm")
  usernameInput = document.querySelector("#usernameField")
  passwordInput = document.querySelector("#passwordField")
  window.getTime().then((t) ->
    console.log("signin.coffee under construction at time " + t)
    return
  )
  return
