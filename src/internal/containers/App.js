import React from "react"
import { connect } from "react-redux"
import { RouteTransition } from "react-router-transition"

const closestByWidth = (width, items) => {
  if (items) {
    return items.reduce((closest, item) => {
      if (!closest || Math.abs(width - closest.width) > Math.abs(item.width - width)) {
        closest = item
      }
      return closest
    })
  }
}

class NavBar extends React.Component {
  render() {
    const STYLES = {
      base: {
        flexDirection: "row",
        height: 44,
        borderTopWidth: 1,
        backgroundColor: "rgba(255,255,255,0.4)"
        //justifyContent: "space-between"
      },

      item: {
        flex: 1,
        alignItems: "center",
        alignContent: "flex-end"
      }
    }
    return <div style={{...STYLES.base, ...this.props.style}}>
      { React.Children.map(this.props.children, (child, index) => <div key={index} style={STYLES.item}>{child}</div>) }
    </div>
  }
}

class App extends React.Component {
  render() {
    const { children, board = {} } = this.props
    const {
      backgroundImageScaled,
      backgroundColor="lightgray",
      backgroundBrightness
    } = board.prefs || {}
    const backgroundImage = closestByWidth(window.outerWidth, backgroundImageScaled)
    return <div style={Object.assign(
      {},
      STYLES.brightness[backgroundBrightness],
      {
        height:"100vh",
        width: "100vw",
        backgroundColor: backgroundColor,
        backgroundImage: backgroundImage && `url(${backgroundImage.url})`
      })}>
      <div style={STYLES.appbar}>trello-mx</div>
      <div style={STYLES.content}>
        {children}
      </div>
      <NavBar style={STYLES.navbar}>
        <div>Activities</div>
        <div>Notifications</div>
        <div>Profile</div>
        <div>Boards</div>
      </NavBar>
    </div>
  }
}
const select = (state, ownProps) => {
  return {
    board: state.boards.items[state.boards.byId[ownProps.params.id]]
  }
}
export default connect(select)(App)

const STYLES = {
  appbar: {
    flex: "none"
  },

  content: {
    flex: 1
  },

  navbar: {
    flex: "none"
  },

  brightness: {
    dark: {
      color: "white"
    },
    light: {
      color: "black"
    }
  }
}
