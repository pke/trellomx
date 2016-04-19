import React from "react"
import moment from "moment"

const PROPTYPES = {
  date: React.PropTypes.oneOfType([
    React.PropTypes.instanceOf(Date),
    React.PropTypes.number,
    React.PropTypes.string
  ]).isRequired
}

const STYLES = {
  base: {

  },

  soon: {
    backgroundColor: "orange"
  },

  overdue: {
    backgroundColor: "red"
  }
}

const DueBadge = ({date}) => {
  date = (date instanceof Date) ? date : new Date(date)
  const finalStyle = {
    ...STYLES.base,
    ...date.getTime() < Date.now() && STYLES.overdue}
  return <div style={finalStyle}>{moment(date).format("LL")}</div>
}
DueBadge.propTypes = PROPTYPES
export default DueBadge
