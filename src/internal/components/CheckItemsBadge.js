import React from "react"

const PROPTYPES = {
  total: React.PropTypes.number.isRequired,
  checked: React.PropTypes.number.isRequired
}

const CheckItemsBadge = ({total, checked}) => (
  <div>{checked}/{total}</div>
)
CheckItemsBadge.propTypes = PROPTYPES
export default CheckItemsBadge
