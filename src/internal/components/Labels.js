import React from "react"

import Label from "./Label"

const PROPTYPES = {
  labels: React.PropTypes.array.isRequired
}

const Labels = (props) => {
  const { labels } = props
  const STYLES = {
    base: {
      flexDirection: "row",
      flexWrap: "wrap"
    }
  }
  return <div style={STYLES.base}>
    { labels.map((label, index) => <Label key={index} {...label}/>)}
  </div>
}
Labels.propTypes = PROPTYPES
export default Labels
