class BookCheckbox extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      checked: Boolean(props.checked)
    };
  }

  render() {
    const toggle = () => {
      const newCheckedState = !this.state.checked;

      this.setState({checked: newCheckedState});
      if (this.props.onChange) {
        this.props.onChange({
          value: this.props.value,
          checked: newCheckedState
        })
      }
    };
    const classes = [
      'book-checkbox',
      this.state.checked ? 'checked' : ''
    ].join(' ');
    const checkIfChecked = this.state.checked ?
      <span className="fa fa-check"></span> :
      null;

    return (
      <div
        className={classes}
        onClick={toggle}
      >
        <input type="checkbox"
          hidden
          name={this.props.name}
          value={this.props.value}
          checked={this.state.checked}
         />
        <img src={this.props.imageUrl} />
        <label>{this.props.label}</label>
        <div className="indicator">
          {checkIfChecked}
        </div>
      </div>
    );
  }

}
