import React from "react"

export const SizeType = React.PropTypes.oneOf(["small", "large"])

const PROPTYPES = {
  avatarId: React.PropTypes.string.isRequired,
  size: SizeType
}
const MemberAvatar = ({avatarId,size = "large",style}) => {
  size = size === "small" ? 30 : 170
  return <img src={`https://trello-avatars.s3.amazonaws.com/${avatarId}/${size}.png`} style={style}/>
}
MemberAvatar.propTypes = PROPTYPES
export default MemberAvatar