import React from "react"
import DueBadge from "./DueBadge"

const PROPTYPES = {

}
const STYLES = {
  fontSize: "smaller"
}

const Badge = (props, context) => {
  const { name, value, children } = props
  if (!value) {
    return null
  }
  let content
  switch (name) {
  case "due":
    content = <DueBadge date={value}/>
    break
  default: content = <div>{value !== true ? value : null}</div>
  }

  return <div style={STYLES}>
    <div>{name}</div>
    { content }
  </div>
}
Badge.propTypes = PROPTYPES
export default Badge
