
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

  boardInvoked: WinJS.UI.eventHandler (event) ->
    # The handler can be invoked by an ItemContainer or ListViewItem
    # If invoked by an ItemContainer it needs to have a "board" property bound
    boardPromise = if event.target.board
      WinJS.Promise.as(event.target.board)
    else if event.detail.itemPromise
      event.detail.itemPromise
      .then (item) ->
        board = item.data
    else
      debugger
      WinJS.Promise.wrapError("InvokeHandlerError", "You need to specify a board if its not bound to a listview item")
    boardPromise
    .then (board) ->
      if board.id is "login"
        trello.api.authorizeAsync()
        .then null, (error) ->
          return
      else if board.id is "add"
        addBoard(event)
      else
        trello.show("/boards/#{board.id}")
        #WinJS.Navigation.navigate("/pages/boardPage.html", board:board)

WinJS.UI.Pages.define "/pages/homePage.html",
  init: (element, options) ->
    @refresher = trello.app.model.refreshAsync()
    return # Don't wait for the promise, displays the page faster

  processed: (element, options) ->

  ready: (element, options) ->
