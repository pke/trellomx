
Board = trello.model.define "Board",
  properties:
    name: {}

Board::performAction = (action, model) ->
  if action.type is "updateBoard"
    if action.data.old.name
      @name = action.data.board.name

WinJS.Namespace.define "trello.app.model",
  Board: Board