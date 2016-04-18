
WinJS.UI.Pages.define "/pages/_addBoard.html",
  processed: (element, options) ->
    organizationSelect = element.querySelector("select[name=organization]")
    permissionSelect = element.querySelector("select[name=permission]")
    organizationSelect.value = "0"
    organizationSelect.onchange = () ->
      # If the org permission becomes disabled and was selected,
      # then select the first option (private)
      permissionOption = permissionSelect.querySelector("option[value=org]")
      if permissionOption.disabled = organizationSelect.value is "0"
        if permissionSelect.value is "org"
          permissionSelect.value = permissionSelect.options[0].value
    submitButton = element.querySelector("button[type=submit]")
    element.onsubmit = (event) ->
      submitButton.disabled = true
      elements = event.target.elements
      postArgs =
        name: elements.title.value
        prefs_permissionLevel: elements.permission.value
      if elements.organization.value isnt "0"
        postArgs.idOrganization = elements.organization.value
      # We deliberatly not trim() here to allow the creation of empty boards
      # when the user just enters a space in listnames
      if elements.listNames.value
        postArgs.defaultLists = false
      trello.api.postAsync("/boards", postArgs)
      .then (board) ->
        board.lists or= []
        trello.app.model.boards.push(board = new trello.app.model.Board(board))
        elements.listNames.value.split(",").reduce((lastPromise, listName) ->
          lastPromise.then () ->
            if listName
              trello.api.postAsync("/boards/#{board.id}/lists",
                name:listName,
                pos:"bottom"
              ).then (list) ->
                board.lists.push(list)
        , WinJS.Promise.as()
        ).then () ->
          flyout?.hide()
          unless flyout
            WinJS.Navigation.history.current.initialPlaceholder = true
          WinJS.Navigation.navigate("/pages/boardPage.html", board:board)
          .then () ->
            return#WinJS.Navigation.history.backStack.pop() unless flyout
      .then null, (error) ->
        element.querySelector(".error")?.textContent = error.message
      .then () ->
        submitButton.disabled = false
      false # prevent submit
    if flyout = element.querySelector(".addBoard").winControl
      flyout.show(options.anchor)
      flyout.onafterhide = () ->
        flyout.element.parentElement.removeChild(flyout.element)
