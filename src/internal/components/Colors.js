import React from "react"

const COLORS = {
  green:  "#70b500",
  yellow: "#f2d600",
  orange: "#ff9f1a",
  red:    "#eb5a46",
  purple: "#c377e0",
  blue:   "#0079bf",
  pink:   "#ff78cb",
  sky:    "#00c2e0",
  lime:   "#51e898",
  black:  "#4d4d4d"
}
export default COLORS

export const ColorType = React.PropTypes.oneOf(Object.keys(COLORS))

export const getColorStyles = ({background,backgroundColor,backgroundBrightness}) => {
  const backColor = backgroundColor || COLORS[background] || "#edeff0"
  const textColor = backgroundBrightness === "dark" ? "white" : "black"
  return {
    backgroundColor: backColor,
    color: textColor
  }
}
