import React from "react"

import Badge from "./Badge"
import CheckItemsBadge from "./CheckItemsBadge"

const BadgesShape = {
  votes: React.PropTypes.number,
  viewingMemberVoted: React.PropTypes.bool,
  subscribed: React.PropTypes.bool,
  fogbugz: React.PropTypes.string,
  checkItems: React.PropTypes.number,
  checkItemsChecked: React.PropTypes.number,
  comments: React.PropTypes.number,
  attachments: React.PropTypes.number,
  description: React.PropTypes.bool,
  due: React.PropTypes.string
}

const PROPTYPES = {
  badges: React.PropTypes.shape(BadgesShape).isRequired
}
const STYLES = {
  base: {
    flexDirection: "row",
    flexWrap: "wrap"
  }
}
const NAMES = [ "votes", "checkItems", "comments", "attachments", "description", "due" ]

const Badges = ({badges}) => {
  const usedBadges = NAMES.filter(name => badges[name])
  return <div style={STYLES.base}>
    { usedBadges.map(name => name === "checkItems"
      ? <CheckItemsBadge key={name} total={badges[name]} checked={badges[name+"Checked"]}/>
      : <Badge key={name} name={name} value={badges[name]}/>
    )}
  </div>
}
Badges.propTypes = PROPTYPES
export default Badges
