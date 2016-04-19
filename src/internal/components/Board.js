import React from "react"

import List from "./List"

const PROPTYPES = {
  lists: React.PropTypes.array,
  cards: React.PropTypes.array
}
const Board = ({lists, cards}) => {
  const openLists = lists.filter(list => !list.closed)
  return <div style={{...STYLES.base }}>
    <div style={STYLES.lists}>
      { openLists.map(list => {
        const listCards = cards.filter(card => card.idList === list.id)
        return <List key={list.id} {...list} cards={listCards}/>
      })}
    </div>
  </div>
}
Board.propTypes = PROPTYPES
export default Board

const STYLES = {
  base: {
    flex: 1
  },

  title: {
    flex: "none"
  },

  lists: {
    flex: 1,
    flexDirection: "row",
    overflowX: "auto",
    overflowY: "hidden",
    height:"100vh"
  }
}
