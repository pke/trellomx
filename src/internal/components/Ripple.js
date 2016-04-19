import React from "react"

const rippleAnimation = document.createElement("style")
rippleAnimation.type = "text/css"
document.head.appendChild(rippleAnimation)
rippleAnimation.sheet.insertRule(`
  @keyframes ripple {
    /*scale the element to 250% to safely cover the entire button and fade it out*/
    100% {opacity: 0; transform: scale(2.5);}
  }`, 0)
  
  
class Ripple extends React.Component {
  constructor(props) {
    super(props)
    this.state = { touched: false }
    this.toggle = this.toggle.bind(this)
  }
  
  componentDidMount() {
    this.refs.ripple.parentElement.style.position = "relative"
    this.refs.ripple.parentElement.addEventListener("mousedown", this.toggle)
  }
  
  componentWillUnmount() {
    this.refs.ripple.parentElement.removeEventListener("mousedown", this.toggle)
  }
  
  toggle(event) {
    const parent = this.refs.ripple.parentElement
    const rect = parent.getBoundingClientRect()
    const top = rect.top + document.body.scrollTop
    const left =  rect.left + document.body.scrollLeft
    
    const d = Math.max(parent.offsetWidth, parent.offsetHeight)    
    this.rippleX = (event.pageX - left - d / 2) + "px"
    this.rippleY = (event.pageY - top - d / 2) + "px"
    this.rippleSize = d + "px"
    this.setState({ touched: Date.now() })
  } 
  
  render() {
    const STYLES = {
      clip: {
        position: "absolute",
        left: 0,
        top: 0,
        bottom: 0,
        right: 0,
        overflow: "hidden",
        pointerEvents: "none"
      },
      
      base: {
        display: "block",
        position: "absolute",
        pointerEvents: "none",        
        borderRadius: "100%",
        transform: "scale(0)",
        background: "rgba(0,0,0,.4)"
      },
      
      touched: {
        animation: "ripple 0.35s linear"
      }
    }
    const left = this.rippleX
    const top = this.rippleY
    const width = this.rippleSize
    const height = width
    
    return <div ref="ripple" style={STYLES.clip}>
      <div key={this.state.touched} style={{
        ...STYLES.base,
        left,
        top, 
        width,
        height,
        ...this.state.touched && STYLES.touched}}>
      </div>
    </div>
  }
}
export default Ripple