# The home model describes what is visible on the home screen


_showClosedBoards = false

boards = new WinJS.Binding.List()
filteredBoards = boards.createFiltered (board) ->
  if board.closed
    return _showClosedBoards
  true

boardStars = new WinJS.Binding.List()
inspirationBoards = new WinJS.Binding.List()
publicBoards = new WinJS.Binding.List()
organizations = new WinJS.Binding.List([
  displayName: "(none)" #i18n
  id:0
]).createSorted (orgA, orgB) ->
  if orgA.id is 0
    return -1
  else if orgB.id is 0
    return 1
  orgA.displayName.localeCompare(orgB.displayName)


WinJS.Application.addEventListener "trello/loggedin", () ->
  trello.app.model.refreshAsync()
WinJS.Application.addEventListener "trello/loggedout", () ->
  trello.app.model.refreshAsync()

WinJS.Namespace.define "trello.app.model",
  boards: filteredBoards
  showClosedBoards:
    get: -> _showClosedBoards
    set: (value) ->
      _showClosedBoards = value
      boards.notifyReload()
  boardStars: boardStars
  inspirationBoards: inspirationBoards
  publicBoards: publicBoards
  organizations: organizations
  refreshAsync: () ->
    unless inspirationBoards.length
      trello.api.getPublicAsync("/organizations/54b58957112602c9a0be7aa3/boards")
      .then (boards) ->
        inspirationBoards.push.apply(inspirationBoards, boards.map (board) -> new trello.app.model.Board(board))
    unless publicBoards.length
      randomInt = (min, max) ->
        Math.floor(Math.random() * (max - min + 1)) + min
      WinJS.xhr(
        url:"https://www.google.com/search?q=site:trello.com/b/&start=#{randomInt(0,100)*10}"
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
            , (error) ->
              console.error("Could not fetch supposed public board #{boardId}", error.message)
    if trello.api.loggedIn
      myBoardPromise = trello.api.meAsync(
        boards:"all"
        board_fields:"all"
        organizations: "all"
      ).then (my) ->
        organizations.splice(1, organizations.length - 1, my.organizations...)
        my.boards.push(new trello.app.model.Board(
          id: "add"
          name: "Add board..." #i18n
          icon: WinJS.UI.AppBarIcon.add
          prefs:
            backgroundColor: "#70B500"
        ))
        return my
    else
      myBoardPromise = WinJS.Promise.as(
        boards: [new trello.app.model.Board(
          id: "login"
          name: "Login or register to see your boards" #i18n
          prefs:
            backgroundColor: "#70B500"
        )]
      )
    myBoardPromise
    .then (my) ->
      boards.splice(0, boards.length)
      my.boards.forEach (board) ->
        board.location = "/pages/boardPage.html"
        board.state = board.id
        board.label = board.name
        boards.push(new trello.app.model.Board(board))
