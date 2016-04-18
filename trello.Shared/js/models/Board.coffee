
Board = trello.model.define "Board",
  ctor: (properties) ->
    WinJS.Application.addEventListener "notification/#{@id}", ({action, model}) =>
      @performAction?(action, model)

  properties:
    name: {}

Board::performAction = (action, model) ->
  if action.type is "updateBoard"
    Object.keys(action.data.old).forEach( (property) ->
      if typeof action.data.board[property] is "object"
        Object.keys(action.data.board[property]).forEach((name) ->
          @[property][name] = action.data.board[property][name]
        , this)
      else
        @[property] = action.data.board[property]
    , this)

Board::listsAsync = () ->
  if @lists
    WinJS.Promise.as(@lists)
  else
    trello.api.getBoardAsync(@id, lists: "open", fields: "all")
    .then (board) =>
      @lists = board.lists

WinJS.Namespace.define "trello.app.model",
  Board: Board