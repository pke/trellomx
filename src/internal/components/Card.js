import React from "react"

import Badges from "./Badges"
import Labels from "./Labels"

const PROPTYPES = {
  name: React.PropTypes.string.isRequired,
  desc: React.PropTypes.string,
  badges: React.PropTypes.object,
  labels: React.PropTypes.array
}
const Card = (props) => {
  const { name, badges, labels, desc } = props
  const STYLES = {
    base: {
      flex: "none",
      backgroundColor: "rgba(0,0,0,0.5)",
      margin: "6px 0",
      padding: 6,
      color:"white"
    },
    name: {
      wrap: "nowrap",
      flex: "none"
    }
  }
  return <div style={STYLES.base}>
    <div style={STYLES.name}>{name}</div>
    <Badges badges={badges}/>
    <Labels labels={labels}/>
  </div>
}
Card.propTypes = PROPTYPES
export default Card
