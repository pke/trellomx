
pubnub = PUBNUB.init(
  publish_key: 'pub-c-0b20bfbc-2c49-4f20-82ac-659d8ebb490c'
  subscribe_key: 'sub-c-f3c0a50c-d79f-11e4-9532-0619f8945a4f'
)

#FIXME: Do not export this, its currently used in the boardPage for card movement
WinJS.Namespace.define "trello", pubnub: pubnub

passwordVault = Windows.Security.Credentials.PasswordVault()

#HACK remove this if known how to do Auth continuation properly on WindowsPhone
if WinJS.Utilities.isPhone
  token = "73207b09afd8dc51cf4db9d5fa7be25244b638877de3c5a839d6221eceecf5af"
  password = new Windows.Security.Credentials.PasswordCredential("trello", "Philipp Kursawe", token)
  passwordVault.add(password)


TrelloAPI = WinJS.Class.define (@version, @key, @secret) ->
  @apiRootUrl = "https://api.trello.com/#{@version}"
  @authorizeUrl = "https://trello.com/#{@version}/authorize"
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

  # FIXME: does this need to be an instance method or could be static?
  _toQueryString: (params) ->
    queryParams = (Object.keys(params).map (key) -> "#{key}=#{encodeURIComponent(params[key])}").join("&")

  _requestAsync: (method, path, params = {}) ->
    params["key"] = @key
    params["token"] or= @token if @token
    url = "#{@apiRootUrl}#{path}?#{@_toQueryString(params)}"
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
    # TODO: Unregister all webhooks here, what happens if unregister fails?
    # What happens if we are offline?
    passwordVault.remove(passwordVault.retrieveAll().getAt(0))
    # No token and no _me promise anymore
    @token = @_me = null

  getBoardAsync: (id, params) ->
    # TODO:
    # Give cached version first as quickly as possible.
    # Then try to fetch an update from the server
    # if the update differs, update the cached model
    @getPublicAsync("/boards/#{id}", params)
    .then (board) =>
      board = new trello.app.model.Board(board)
      @watchAsync(board)
      board.unwatch = @unwatch.bind(@, board)
      board

  # Saves all registered webhooks by id
  # With a reference counter. If the refcounter goes to 0, the webhook is deleted
  _webhooks: {}

  watchAsync: (model) ->
    webhook = @_webhooks[model.id] or= {}
    if webhook.refCount
      webhook.refCount = webhook.refCount + 1
      return WinJS.Promise.as(webhook)
    else if @loggedIn #FIXME: After login register for all pending models (where .refCount is undefined)
      @createWebhookAsync(
        description: model.name
        idModel: model.id
        #HACK: Hardcoded hostname:port
        #See pubnubserver/README.md for details
        #In the final version the host should be pubnub
        callbackURL: "http://pfcpille.no-ip.biz:1337/#{model.id}"
      ).then () =>
        webhook.refCount = 1
        pubnub.subscribe(
          channel: model.id
          message: (message) =>
            WinJS.Application.queueEvent(type: "notification/#{model.id}", model:message.model, action:message.action)
        )
        webhook
    else
      return WinJS.Promise.as(webhook)

  unwatch: (model) ->
    if webhook = @_webhooks[model.id]
      if (webhook.refCount = webhook.refCount - 1) is 0
        delete @_webhooks[model.id]
        # TODO: delete webhook

  createWebhookAsync: (params) ->
    # FIXME: check if the webhook is already registered and not just always try
    # to register it again.
    # FIXME: Also this should auto-retry if it fails because of network connectivity
    # So that when the net comes back in, we will be able to register the hook.
    @postAsync("/tokens/#{@token}/webhooks", params)
    .then null, (error) ->
      # Ignore errors in re-registering webooks
      return

  getWebhooksAsync: () ->
    @getAsync("/tokens/#{@token}/webhooks")

  authorizeAsync: (expiration = "never") ->
    return WinJS.Promise.as(@token) if @token

    queryString = @_toQueryString(
      callback_method: "fragment"
      return_url: "https://www.trello.com"
      scope: "read,write,account"
      expiration: expiration
      name: "Trello Windows App"
      key: @key
    )
    startUri = new Windows.Foundation.Uri("#{@authorizeUrl}?#{queryString}")
    # The WAB checks for this URL to understand the authorization process has finished.
    endUri = new Windows.Foundation.Uri("https://trello.com/token")
    # Protect against double calls, by remembering the first call in a promise
    @_authorizing or= Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAsync(
      Windows.Security.Authentication.Web.WebAuthenticationOptions.none, startUri, endUri)
    .then (result) =>
      if result.responseStatus is Windows.Security.Authentication.Web.WebAuthenticationStatus.success
        #FIXME: check for proper token format here
        token = result.responseData.replace("https://trello.com/token=", "")

        #FIXME: Add error handling here with retry-method for potential connection problems
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
