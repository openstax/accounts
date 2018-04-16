//= require ../vendor/react-classnames
//= require ../vendor/react-input-autosize
//= require ../vendor/react-select

class OSSelect extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      selectedOption: props.options.find((o) => o.value === props.value),
    };
    this.handleChange = (selectedOption) => {
      this.setState({ selectedOption });
    };
  }

  render() {
    const { selectedOption } = this.state;
    const value = selectedOption && selectedOption.value;

    return (
      <Select
        className={this.props.className}
        clearable={false}
        searchable={false}
        filterOptions={true}
        name={this.props.name}
        value={value}
        onChange={this.handleChange}
        options={this.props.options}
      />
    );
  }

}
