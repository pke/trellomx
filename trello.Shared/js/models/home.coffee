# The home model describes what is visible on the home screen

boards = new WinJS.Binding.List()
boardStars = new WinJS.Binding.List()
inspirationBoards = new WinJS.Binding.List()
publicBoards = new WinJS.Binding.List()

WinJS.Namespace.define "trello.app.model",
  boards: boards
  boardStars: boardStars
  inspirationBoards: inspirationBoards
  publicBoards: publicBoards
  refreshAsync: () ->
    unless inspirationBoards.length
      trello.api.getPublicAsync("/organizations/54b58957112602c9a0be7aa3/boards")
      .then (boards) ->
        inspirationBoards.push.apply(inspirationBoards, boards)

    unless publicBoards.length
      WinJS.xhr(
        url:"https://www.google.com/search?q=site:trello.com/b/&start=0"
        responseType: "document"
      ).then (result) ->
        doc = result.response
        links = doc.querySelectorAll("li.g a[href^='https://trello.com']")
        for link in links
          [_,boardId] = link.href.match(/https:\/\/trello\.com\/b\/(\w+)/i)
          if boardId
            trello.api.getPublicAsync("/boards/#{boardId}")
            .then (board) ->
              publicBoards.push(board)
    if trello.api.loggedIn
      myBoardPromise = trello.api.getAsync("/members/me", boards:"all", board_fields:"all")
      .then (my) ->
        my.boards.push(
          id: "add"
          name: "Add board..."
          icon: WinJS.UI.AppBarIcon.add
          prefs:
            backgroundColor: "#70B500"
        )
        return my
    else
      myBoardPromise = WinJS.Promise.as(
        boards: [
          id: "login"
          name: "Login or register to see your boards"
          prefs:
            backgroundColor: "#70B500"
        ]
      )
    myBoardPromise
    .then (my) ->
      boards.splice(0, boards.length)
      my.boards.forEach (board) ->
        board.location = "/pages/board.html"
        board.state = board.id
        board.label = board.name
        boards.push(board)
