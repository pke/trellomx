
passwordVault = Windows.Security.Credentials.PasswordVault()

#HACK remove this if known how to do Auth continuation properly on WindowsPhone
if WinJS.Utilities.isPhone
  token = "73207b09afd8dc51cf4db9d5fa7be25244b638877de3c5a839d6221eceecf5af"
  password = new Windows.Security.Credentials.PasswordCredential("trello", "Philipp Kursawe", token)
  passwordVault.add(password)

TrelloAPI = WinJS.Class.define (@version, @key, @secret) ->
  @requestRoot = "https://api.trello.com/#{@version}"
  passwordCredentials = passwordVault.retrieveAll()
  if passwordCredentials.size and cred = passwordCredentials.getAt(0)
    cred.retrievePassword()
    @token = cred.password
  return
,
  loggedIn: get: -> !!@token

  # Ensures that we have a valid token before sending the request
  _requestPrivateAsync: (method, path, params = {}) ->
    (if params.token then WinJS.Promise.as() else @authorizeAsync())
    .then () =>
      params["token"] or= @token
      @_requestAsync(method, path, params)

  _requestAsync: (method, path, params = {}) ->
    params["key"] = @key
    params["token"] or= @token if @token
    queryParams = (Object.keys(params).map (key) -> "#{key}=#{encodeURIComponent(params[key])}").join("&")
    url = "#{@requestRoot}#{path}?#{queryParams}"
    WinJS.xhr(url: url, type: method)
    .then (result) ->
      try
        JSON.parse(result.responseText)
      catch e
        WinJS.Promise.wrapError(new WinJS.ErrorFromName("trello", "Could not parse response for " + url + " :" + e.message))

  getPublicAsync: (path, params) ->
    @_requestAsync("GET", path, params)

  getAsync: (path, params) ->
    @_requestPrivateAsync("GET", path, params)

  postAsync: (path, params) ->
    @_requestPrivateAsync("POST", path, params)

  putAsync: (path, params) ->
    @_requestPrivateAsync("PUT", path, params)

  deleteAsync: (path, params) ->
    @_requestPrivateAsync("DELETE", path, params)

  meAsync: () ->
    #If this runs into error condition, it will always return
    #the error state of the promise. So, add an error handler here and
    #reset @_me to null so the next request might try it again
    @_me or= @getAsync("/members/me")
    .then null, (error) =>
      @_me = null
      WinJS.Promise.wrapError(error)

  logout: ->
    passwordVault.remove(passwordVault.retrieveAll().getAt(0))
    # No token and no _me promise anymore
    @token = @_me = null

  createWebhookAsync: (params) ->
    # FIXME: check if the webhook is already registered and not just always try
    # to register it again.
    # FIXME: Also this should auto-retry if it fails because of network connectivity
    # So that when the net comes back in, we will be able to register the hook.
    @postAsync("/tokens/#{@token}/webhooks", params)
    .then null, (error) ->
      # Ignore errors in re-registering webooks
      return

  authorizeAsync: ->
    return WinJS.Promise.as(@token) if @token

    startUri = new Windows.Foundation.Uri("https://trello.com/#{@version}/authorize?callback_method=fragment&return_url=https%3A%2F%2Fwww.trello.com&scope=read,write,account&expiration=never&name=trello%20Windows%20App&key=#{@key}")
    # The WAB checks for this URL to understand the authorization process is finished.
    endUri = new Windows.Foundation.Uri("https://trello.com/token")
    # Protect against double calls, by remembering the first call in a promise
    @_authorizing or= Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAsync(
      Windows.Security.Authentication.Web.WebAuthenticationOptions.none, startUri, endUri)
    .then (result) =>
      if result.responseStatus is Windows.Security.Authentication.Web.WebAuthenticationStatus.success
        token = result.responseData.replace("https://trello.com/token=", "")
        @getAsync("/members/me", token:token)
        .then (account) =>
          password = new Windows.Security.Credentials.PasswordCredential("trello", account.fullName, @token = token)
          passwordVault.add(password)
          return
      else
        if result.responseStatus is Windows.Security.Authentication.Web.WebAuthenticationStatus.userCancel
          WinJS.Promise.wrapError(new WinJS.ErrorFromName("Canceled"))
        else
          WinJS.Promise.wrapError(new WinJS.ErrorFromName("trello", "Login error: #{result.responseErrorDetail}"))
    .then null, (error) =>
      # Make sure subsequent calls try again to use the WAB,
      # by clearing the promise that would be usually returned
      # from this method
      @_authorizing = null
      WinJS.Promise.wrapError(error)

WinJS.Namespace.define "trello",
  api: new TrelloAPI(1, trello.apiKeys.apiKey, trello.apiKeys.apiSecret)
