import React from "react"

import MemberAvatar, { SizeType } from "./MemberAvatar"

const PROPTYPES = {
  members: React.PropTypes.arrayOf(React.PropTypes.shape({
    id: React.PropTypes.string.isRequired,
    avatarHash: React.PropTypes.string.isRequired
  })),
  size: SizeType,
  style: React.PropTypes.object,
  itemStyle: React.PropTypes.object
}

const MemberAvatars = ({members, size="small", style={}, itemStyle={}}) => {
  const STYLES = {
    base: {
      flexDirection: "row"
    },
    item: {
      paddingRight: 2
    }
  }
  return <div style={{...STYLES.base, ...style}}>
    { members.map(member => (
      <div key={member.id} style={{...STYLES.item, ...itemStyle}}>
        <MemberAvatar avatarId={member.avatarHash} size={size}/>
      </div>
    ))}
  </div>
}
MemberAvatars.propTypes = PROPTYPES
export default MemberAvatars