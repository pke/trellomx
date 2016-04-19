import React from "react"
import { render } from "react-dom"

class Button extends React.Component {
  render() {
    const STYLES = {
      button: {
        userSelect: "none",
        outline: 0,
        cursor: "pointer",
        height: 48,
        padding: "0 2em",
        border: 0,
        background: "red",
        color: "white"
      }
    }
    return <button style={STYLES.button}>
       { this.props.children }
     </button>
  }
}

import routes from "./internal/routes"

import { Provider } from "react-redux"
import { Router, hashHistory as history } from "react-router"

class Root extends React.Component {
  render() {
    const { store, history } = this.props
    return <Provider store={store}>
      <Router history={history} routes={routes} />
    </Provider>
  }
}

import { syncHistoryWithStore } from "react-router-redux"

import configureStore from "./store/configureStore"
const store = configureStore()
const syncedHistory = syncHistoryWithStore(history, store)

render(<Root store={store} history={syncedHistory}/>, document.getElementById("app"))
