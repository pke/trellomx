
const BOARD1 = require("./trello-mx.json")
const BOARD2 = require("./end-of-summer.json")
const BOARD3 = require("./the-dev-board.json")

const INITIAL_STATE = {
  byId: {
    [BOARD1.shortLink]: 0,
    [BOARD2.shortLink]: 1,
    [BOARD3.shortLink]: 2
  },
  items: [BOARD1, BOARD2, BOARD3]
}
export default function boardsReducer(state = INITIAL_STATE, action) {
  switch (action.type) {
  default:
    return state
  }
}
