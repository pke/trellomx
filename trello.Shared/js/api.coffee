define ["apiKeys"], (ApiKeys) ->

  isWin10 = Windows.Foundation.Metadata.ApiInformation isnt undefined
  passwordVault = Windows.Security.Credentials.PasswordVault()

  TrelloAPI = WinJS.Class.define (options) ->
    @webhookCallbackUrl = options.webhookCallbackUrl
    @appName = options.appName
    @version = options.version or 1
    @apiKey = options.apiKey
    @apiSecret = options.apiSecret
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
      (if params.token then WinJS.Promise.as(params.token) else @authorizeAsync())
      .then (token) =>
        params["token"] or= @token
        @_requestAsync(method, path, params)

    # FIXME: does this need to be an instance method or could be static?
    _toQueryString: (params) ->
      queryParams = (Object.keys(params).map (key) -> "#{key}=#{encodeURIComponent(params[key])}").join("&")

    _requestAsync: (method, path, params = {}) ->
      params["key"] = @apiKey
      params["token"] or= @token if @token
      url = "#{@apiRootUrl}#{path}?#{@_toQueryString(params)}"
      WinJS.xhr(url: url, type: method)
      .then (result) ->
        try
          JSON.parse(result.responseText)
        catch e
          WinJS.Promise.wrapError(new WinJS.ErrorFromName("TrelloApiError", "Could not parse response: #{e.message}"))
      , (errorResponse) ->
        WinJS.Promise.wrapError(new WinJS.ErrorFromName("TrelloApiError", "#{errorResponse.status} #{errorResponse.statusText}: #{errorResponse.responseText}"))
      .then null, (error) ->
        console.error("Could not #{method} #{url}: #{error.message}")
        WinJS.Promise.wrapError(new WinJS.ErrorFromName("TrelloApiError", "Error #{method} #{path}: #{error.message} (#{url})"))

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

    meAsync: (options) ->
      #If this runs into error condition, it will always return
      #the error state of the promise. So, add an error handler here and
      #reset @_me to null so the next request might try it again
      @_me or= @getAsync("/members/me", options)
      .then (me) =>
        @watchAsync(me)
        @_me = null
        if me.boards
          me.boards = me.boards.map((board) ->
            #@watchAsync(board)
            new trello.app.model.Board(board)
          , this)
        me
      , (error) =>
        @_me = null
        WinJS.Promise.wrapError(error)

    logout: ->
      # TODO: Unregister all webhooks here, what happens if unregister fails?
      # What happens if we are offline?
      passwordVault.remove(passwordVault.retrieveAll().getAt(0))
      # No token and no _me promise anymore
      @token = @_me = null
      WinJS.Application.queueEvent(type:"trello/loggedout")

    getBoardAsync: (id, params) ->
      # TODO:
      # Give cached version first as quickly as possible.
      # Then try to fetch an update from the server
      # if the update differs, update the cached model
      @getPublicAsync("/boards/#{id}", params)
      .then (board) =>
        board = new trello.app.model.Board(board)
        #@watchAsync(board)
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
        WinJS.Utilities.Scheduler.schedule(() ->
          @createWebhookAsync(
            description: model.name or model.fullName
            idModel: model.id
            callbackURL: "#{@webhookCallbackUrl}/#{model.id}"
          ).then () =>
            webhook.refCount = 1
            webhook
        , WinJS.Utilities.Scheduler.idle, this)
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
      #return WinJS.Promise.as()
      @postAsync("/tokens/#{@token}/webhooks", params)
      .then null, (error) ->
        console.error("Could not create webhook for #{params.idModel}:#{params.description}")
        # Ignore errors in re-registering webooks
        return
      .then ->
        WinJS.Application.queueEvent(type:"trello/webhook/created", webhook:params)

    getWebhooksAsync: () ->
      @getAsync("/tokens/#{@token}/webhooks")

    deleteWebhookAsync: (id) ->
      @deleteAsync("/tokens/#{@token}/webhooks/#{id}")

    deleteAllWebhooksAsync: () ->
      @getWebhooksAsync().then (webhooks) =>
        next = WinJS.Promise.as()
        webhooks.forEach (webhook) =>
          next = next.then () =>
            @deleteWebhookAsync(webhook.id)
          , (error) ->
            console.error("Could not delete webhook #{webhook.id}")
        next

    _onAuthenticated: (result) ->
      if result.responseStatus is Windows.Security.Authentication.Web.WebAuthenticationStatus.success
        #FIXME: check for proper token format here
        token = result.responseData.replace("#{TrelloAPI._wabReturnUrl}/token=", "")

        #FIXME: Add error handling here with retry-method for potential connection problems
        @getAsync("/members/me", token:token)
        .then (account) =>
          password = new Windows.Security.Credentials.PasswordCredential("trello", account.fullName, @token = token)
          passwordVault.add(password)
          WinJS.Application.queueEvent(type:"trello/loggedin")
          return token
      else if result.responseStatus is Windows.Security.Authentication.Web.WebAuthenticationStatus.userCancel
        WinJS.Promise.wrapError(new WinJS.ErrorFromName("Canceled"))
      else
        WinJS.Promise.wrapError(new WinJS.ErrorFromName("trello", "Login error: #{result.responseErrorDetail}"))

    authorizeAsync: (expiration = "never") ->
      return WinJS.Promise.as(@token) if @token

      queryString = @_toQueryString(
        callback_method: "fragment"
        return_url: TrelloAPI._wabReturnUrl
        scope: "read,write,account"
        expiration: expiration
        name: @appName
        key: @apiKey
      )
      startUri = new Windows.Foundation.Uri("#{@authorizeUrl}?#{queryString}")
      # The WAB checks for this URL to understand the authorization process has finished.
      endUri = new Windows.Foundation.Uri("#{TrelloAPI._wabReturnUrl}/token")
      if not isWin10 and Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAndContinue
        return WinJS.Promise.as(Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAndContinue(startUri, endUri, null, Windows.Security.Authentication.Web.WebAuthenticationOptions.none))
      # Protect against double calls, by remembering the first call in a promise
      @_authorizing or= Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAsync(
        Windows.Security.Authentication.Web.WebAuthenticationOptions.none, startUri, endUri)
      .then(@_onAuthenticated.bind(@))
      .then null, (error) =>
        # Make sure subsequent calls try again to use the WAB,
        # by clearing the promise that would be usually returned
        # from this method
        @_authorizing = null
        WinJS.Promise.wrapError(error)
  ,
    _wabReturnUrl: "https://trello.com"

  WinJS.Namespace.define "trello",
    api: new TrelloAPI(
      version: 1
      appName: "Trello MX"
      apiKey: ApiKeys.trello.apiKey
      apiSecret: ApiKeys.trello.apiSecret
      #HACK: Hardcoded hostname:port
      #See pubnubserver/README.md for details
      #In the final version the host should be pubnub
      webhookCallbackUrl: "http://pfcpille.no-ip.biz:1337"
    )

  return