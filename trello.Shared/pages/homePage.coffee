
addBoard = (event) ->
  if WinJS.Utilities.isPhone
    WinJS.Navigation.navigate("/pages/_addBoard.html")
  else
    WinJS.UI.Pages.render("/pages/_addBoard.html", document.body, anchor:event.target)

WinJS.Namespace.define "trello.ui",
  hideSection: WinJS.UI.eventHandler (event) ->
    prev = event.parentElement
    while prev.dataset.winControl isnt "WinJS.UI.HubSection"
      prev = prev.parentElement
    if section = prev.winControl
      prev = prev.parentElement
      while prev.dataset.winControl isnt "WinJS.UI.Hub"
        prev = prev.parentElement
      hub = prev.winControl
      hub.sections.splice(hub.sections.indexOf(section), 1)

  addBoard: WinJS.UI.eventHandler(addBoard)
  
  cardInvoked: WinJS.UI.eventHandler (event) ->

  boardInvoked: WinJS.UI.eventHandler (event) ->
    # The handler can be invoked by an ItemContainer or ListViewItem
    # If invoked by an ItemContainer it needs to have a "board" property bound
    itemPromise = if event.target.item
      WinJS.Promise.as(event.target.item)
    else if event.detail.itemPromise
      event.detail.itemPromise
      .then ({data}) ->
        item = data
    else
      debugger
      WinJS.Promise.wrapError("InvokeHandlerError", "You need to specify a board if its not bound to a listview item")
    itemPromise
    .then (item) ->
      if item.className is "Board"
        if item.id is "login"
          trello.api.authorizeAsync()
          .then null, (error) ->
            return
        else if item.id is "add"
          addBoard(event)
        else
          trello.show("/boards/#{item.id}")
      else #if item.className is "Card"
        WinJS.Navigation.navigate("/pages/cardPage.html", card:item)

WinJS.UI.Pages.define "/pages/homePage.html",
  init: (element, options) ->
    @refresher = trello.app.model.refreshAsync()
    return # Don't wait for the promise, displays the page faster

  processed: (element, options) ->

  ready: (element, options) ->
