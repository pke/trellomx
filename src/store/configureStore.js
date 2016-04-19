import { createStore, applyMiddleware, compose } from "redux"
import createLogger from "redux-logger"

import reducer from "./reducers"

const __DEV__ = process.env.NODE_ENV === "development"
const isDebugging = __DEV__ && !!window.navigator.userAgent

const actionBlackList = ["EFFECT_TRIGGERED", "EFFECT_RESOLVED", "EFFECT_REJECTED"]
const logger = createLogger({
  predicate: (getState, { type }) => isDebugging && actionBlackList.indexOf(type) === -1,
  level: ({ error = false }) => error ? "error" : "log",
  actionTransformer: ({ payload, ...action }) => ({ ...action, ...payload }),
  collapsed: true,
  duration: true
})

const composedStore = compose(
  applyMiddleware(/*thunk, sagas, */logger)
)(createStore)

export default function configureStore(initialState, onComplete) {
  const store = composedStore(reducer, initialState)

  // When using WebPack, module.hot.accept should be used. In LiveReactload,
  // same result can be achieved by using "module.onReload" hook.
  if (module.hot) {
    // Enable Webpack hot module replacement for reducers
    module.hot.accept("./reducers", () => {
      const nextRootReducer = require("./reducers")
      store.replaceReducer(nextRootReducer.default || nextRootReducer)
    })
  } else if (module.onReload) {
    module.onReload(() => {
      const nextRootReducer = require("./reducers")
      store.replaceReducer(nextRootReducer.default || nextRootReducer)
      // return true to indicate that this module is accepted and
      // there is no need to reload its parent modules
      return true
    })
  }

  onComplete && onComplete(store)

  if (isDebugging) {
    window.store = store
  }

  return store
}
