class LabeledInput extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      validationMessage: '',
      value: props.value || ''
    };
  }

  componentDidMount() {
    if (this.inputEl) {
      this.setState({validationMessage: this.inputEl.validationMessage});
    }
  }

  render() {
    const helperText = this.props.helper ? (
      <div className="helper">{this.props.helper}</div>
    ) : null;
    const setInputEl = (el) => {
      this.inputEl = el;
    };
    const handleChange = (event) => {
      this.setState({value: event.target.value});
    };

    return (
      <label className="labeled-input">
        <div className="top-label">{this.props.label}</div>
        {helperText}
        <input
        ref={setInputEl}
        {...{
          className: "form-control",
          ...this.props
        }}
        value={this.state.value}
        onChange={handleChange}
        />
        <div className="invalid-message">{this.state.validationMessage}</div>
      </label>
    );
  }

}
