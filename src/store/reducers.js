import { combineReducers } from "redux"
import { routerReducer as routing } from "react-router-redux"
import { reducer as boards } from "../internal/boards"

const reducer = combineReducers({
  routing,
  boards
})
export default reducer
