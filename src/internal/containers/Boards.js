import React from "react"
import { connect } from "react-redux"
import { getColorStyles } from "../components/Colors"
import { Link } from "react-router"

import Board from "../components/Board"

const closestByHeight = (height, items) => {
  if (items) {
    return items.reduce((closest, item) => {
      if (!closest || Math.abs(height - closest.height) > Math.abs(item.height - height)) {
        closest = item
      }
      return closest
    })
  }
}


const BoardListItem = ({name, desc, prefs, shortLink}) => {
  const STYLES = {
    base: {
      flex: 1,
      position:"relative",
      width: "33%",
      minHeight: 101,
      margin: "0 1em 1em 0",
      backgroundSize: "cover",
      backgroundPosition: "center center"
    },

    name: {
      position: "absolute",
      bottom: 0,
      left: 0,
      right: 0,
      background: "rgba(0,0,0,.4)",
      padding: 6,
      fontWeight: "600"
    },

    fade: {
      position: "absolute",
      bottom: 0,
      left: 0,
      right: 0,
      top: 0,
      background: "rgba(0,0,0,.15)"
    }
  }
  const { backgroundColor, background, backgroundBrightness, backgroundImageScaled } = prefs
  const colorStyle = getColorStyles({backgroundColor, background, backgroundBrightness})
  const backgroundImage = closestByHeight(STYLES.base.minHeight, backgroundImageScaled)
  const backgroundImageStyle = { backgroundImage: backgroundImage && `url(${backgroundImage.url})` }
  return <Link style={{...STYLES.base, ...colorStyle, ...backgroundImageStyle}} to={`/boards/${shortLink}`}>
    <div style={STYLES.fade}></div>
    <div style={STYLES.name}>
      { name }
    </div>
  </Link>
}

const Boards = ({boards, board, params}) => {
  const STYLES = {
    base: {
      flex: "none",
      flexDirection: "row",
      margin: "1em"
    }
  }
  if (params.id) {
    return <Board {...board}/>
  } else {
    return <div style={STYLES.base}>
      { boards.map(board => <BoardListItem key={board.id} {...board}/>)}
      </div>
  }
}

const select = (state, ownProps) => ({
  boards: state.boards.items,
  board: state.boards.items[state.boards.byId[ownProps.params.id]]
})
export default connect(select)(Boards)
