function LabeledRadio(props) {
  return <label className="labeled-radio">
    <input {...{
      type: "radio",
      ...props
    }} />
    {props.label}
  </label>
}
