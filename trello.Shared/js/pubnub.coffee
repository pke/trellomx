define ["lib/pubnub", "apiKeys"], (PubNub, ApiKeys) ->

  pubnub = PUBNUB.init(ApiKeys.pubnub)

  WinJS.Application.addEventListener "trello/webhook/created", ({webhook}) ->
    pubnub.subscribe(
      channel: webhook.idModel
      message: ({action, model}) =>
        console.info("notification: #{action.type}")
        WinJS.Application.queueEvent(type: "notification/#{model.id}", model:model, action:action)
    )
