
marked = null

WinJS.Namespace.define "trello.ui",
  marked: WinJS.Binding.converter (text) ->
    return marked(text);

WinJS.UI.Pages.define "/pages/cardPage.html",
  init: (element, options) ->
    if options.card
      @cardPromise = WinJS.Promise.as(options.card)
    else if options.cardId
      @cardPromise = trello.api.getPublicAsync("/cards/#{cardId}")
    return new WinJS.Promise (c, e) ->
      require(["lib/marked.min"], (_marked) ->
        marked = _marked
        c()
      , e)
  processed: (element, options) ->
    @cardPromise.then (card) =>
      
    WinJS.Binding.processAll(element, @model = WinJS.Binding.as(
      card: options.card
      comments: new WinJS.Binding.List()
    ))
    trello.api.getPublicAsync("/cards/#{@model.card.id}/actions", entities: true, display: true, filter: "commentCard,copyCommentCard")
    .then (comments) =>
      @model.comments.push.apply(@model.comments, comments)
    return
