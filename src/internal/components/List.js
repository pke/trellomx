import React from "react"

import Card from "./Card"

const PROPTYPES = {
  name: React.PropTypes.string.isRequired,
  cards: React.PropTypes.array
}

const List = (props) => {
  const { name, cards } = props
  const STYLES = {
    base: {
      flex: 1,
      padding: 10,
      margin: 10,
      backgroundColor: "rgba(255,255,255,0.5)",
      color: "black",
      minWidth: "200px"
    },

    name: {
      flex: "none",
      fontWeight: "bold"
    },

    cards: {
      flex: 1,
      overflowY: "auto"
    },

    button: {
      flex: "none",
      textAlign: "center",
      paddingTop: 10
    }
  }
  const openCards = cards.filter(card => !card.closed)
  return <div style={STYLES.base}>
    <div style={STYLES.name}><ListTitle>{name}</ListTitle></div>
    <div style={STYLES.cards}>
      { cards.map(card => {
        return <Card key={card.id} {...card}/>
      })}
    </div>
    <div style={STYLES.button}>Add Card...</div>
  </div>
}
List.propTypes = PROPTYPES
export default List


class InPlaceEdit extends React.Component {
  constructor(props) {
    super(props)
    this.state = { edit: props.edit }
    this.cancelEdit = ({target}) => {
      if (this.refs.editor && !this.refs.editor.contains(target)) {
        this.setState({edit:false})
      }
    }
  }

  componentDidMount() {
    document.addEventListener("click", this.cancelEdit, true)
  }

  componentWillUnmount() {
    document.removeEventListener("click", this.cancelEdit, true)
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.edit !== prevState.edit) {
      this.refs.editor.setSelectionRange(0, this.refs.editor.value.length)
    }
  }

  render() {
    const { editor, children } = this.props
    const { edit } = this.state
    if (edit) {
      return React.cloneElement(editor, {ref:"editor", defaultValue:children, style: { border: 0 }})
    } else {
      return <div onClick={() => this.setState({edit:true})}>{children}</div>
    }
  }
}

const ListTitle = (props) => {
  const editor = <input type="text" onChange={props.onChange} autoFocus/>
  return <InPlaceEdit editor={editor}>{props.children}</InPlaceEdit>
}
