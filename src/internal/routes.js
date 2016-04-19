import React from "react"
import { Route, IndexRoute } from "react-router"

import App from "./containers/App"
import Home from "./containers/Home"
import Boards from "./containers/Boards"

export default (
  <Route path="/" component={App}>
    <IndexRoute component={Boards}/>
    <Route path="/boards" component={Boards}>
      <Route path=":id" component={Boards}/>
    </Route>
  </Route>
)
