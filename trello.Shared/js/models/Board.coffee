
WinJS.Namespace.define "trello.ui."
Board = trello.model.define "Board",
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

WinJS.Namespace.define "trello.app.model",
  Board: Board