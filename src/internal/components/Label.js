import React from "react"
import COLORS, { ColorType } from "./Colors"

const PROPTYPES = {
  color: React.PropTypes.oneOfType([
    React.PropTypes.string,
    ColorType
  ]),
  name: React.PropTypes.string.isRequired
}

const STYLES = {
  base: {
    minWidth: "2em",
    color: "white",
    padding: "3px 6px",
    marginRight: 3,
    textOverflow: "ellipsis",
    textShadow: "0 0 5px rgba(0,0,0,.2),0 0 2px #000"
  },

  colors: COLORS
}

const Label = ({color, name}) => {
  return <div style={{...STYLES.base, backgroundColor: STYLES.colors[color]}}>{name}</div>
}
Label.propTypes = PROPTYPES
export default Label
