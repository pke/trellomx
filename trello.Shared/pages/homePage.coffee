
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

  boardInvoked: WinJS.UI.eventHandler (event) ->
    event.detail.itemPromise
    .then (item) ->
      board = item.data
      if board.id is "login"
        trello.api.meAsync()
        .then () ->
          trello.app.model.refreshAsync()
      else if board.id is "add"
        return
      else
        WinJS.Navigation.navigate("/pages/boardPage.html", item.data.id)

WinJS.UI.Pages.define "/pages/homePage.html",
  init: (element, options) ->
    trello.app.model.refreshAsync()
    return # Don't wait for the promise, displays the page faster

  processed: (element, options) ->

  ready: (element, options) ->
