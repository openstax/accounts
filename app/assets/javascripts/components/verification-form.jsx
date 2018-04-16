//= require ./select
//= require ./labeled-input
//= require ./labeled-input
//= require ./book-checkbox

class VerificationForm extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      page: 0,
      using: null,
      validationHasRun: [],
      bookInfo: [],
      selectedBooks: [],
      agreeToTerms: false
    };
    this.bookPromise = fetch('https://openstax.org/api/v2/pages/30/')
    .then((response) => response.json())
    .then((response) => {
      this.setState({bookInfo: response.books.filter((entry) => entry.salesforce_abbreviation)});
    });
  }

  countInvalidFields() {
    const shownInvalids = document.querySelectorAll('.verification-form > :not([hidden]) :invalid');
    const vhr = this.state.validationHasRun.slice();

    vhr[this.state.page] = true;
    this.setState({validationHasRun: vhr});

    return shownInvalids.length;
  }

  render() {
    const nextPage = () => {
      if (this.countInvalidFields() === 0) {
        this.setState({page: this.state.page + 1});
      }
    };
    const prevPage = () => {
      this.setState({page: this.state.page - 1});
    };
    const setUsing = (event) => {
      this.setState({using: event.target.value});
    };
    const delayClass = this.state.validationHasRun[0] ? '' : 'delay-validation';
    const subjects = ['Math', 'Science', 'Social Sciences', 'Humanities'];
    const secondPageHeading = {
      'Confirmed Adoption Won': 'Which book(s) are you using?',
      'Confirmed Will Recommend': 'Which book(s) are you using?',
      'Not using': 'Are you interested in any OpenStax textbooks?'
    }[this.state.using];
    const handleBookCheck = (state) => {
      let selectedBooks = this.state.selectedBooks.slice();

      if (state.checked) {
        selectedBooks.push(state.value);
      } else {
        selectedBooks = selectedBooks.filter((b) => b !== state.value);
      }
      this.setState({selectedBooks});
    };
    const toggleAgreeToTerms = (event) => {
      this.setState({agreeToTerms: !this.state.agreeToTerms});
    };
    const submitDisabled = () => {
      return !(this.state.selectedBooks.length > 0 && this.state.agreeToTerms);
    }

    return <div className="verification-form">
      <div hidden={this.state.page !== 0} className={delayClass}>
        <h1>{this.props.heading}</h1>
        <OSSelect
          className="os-select"
          options={this.props.role.options}
          value={this.props.role.value}
          name="role"
        />
        <LabeledInput {...{
          className: delayClass,
          autoComplete: 'given-name',
          ...this.props.firstName
        }} />
        <LabeledInput {...{
          className: delayClass,
          autoComplete: 'family-name',
          ...this.props.lastName
        }} />
        <LabeledInput {...{
          className: delayClass,
          autoComplete: 'email',
          ...this.props.email
        }} />
        <LabeledInput {...{
          className: delayClass,
          autoComplete: 'phone',
          ...this.props.phone
        }} />
        <LabeledInput {...{
          className: delayClass,
          autoComplete: 'organization',
          ...this.props.school
        }} />
        <h2 className="get-verified-faster">
          {this.props.urlHeading[0]}
          <em> {this.props.urlHeading[1]} </em>
          {this.props.urlHeading[2]}
        </h2>
        <LabeledInput {...{
          className: delayClass,
          autoComplete: 'url',
          ...this.props.url
        }} />
        <h2 className="already-using">
          Already using OpenStax?
        </h2>
        {
          this.props.adoptionStatus.map((entry) =>
            <LabeledRadio
              name="Adoption_Status__c"
              label={entry.label}
              value={entry.value}
              onClick={setUsing}
              key={entry.value}
            />)
        }
        <div className="button-zone">
          <button type="button" className="primary"
            onClick={nextPage}
          >Next</button>
        </div>
      </div>

      <div hidden={this.state.page === 0}>
        <h2>{secondPageHeading}</h2>
        <div className="helper">Select all that apply</div>
        {
          subjects.map((subject) => (
            <div>
              <h3>{subject}</h3>
              <div className="subject-grid">
              {
                this.state.bookInfo
                  .filter((entry) => entry.subject === subject)
                  .map((entry) => (
                    <BookCheckbox name="profile[subjects]"
                      value={entry.salesforce_abbreviation}
                      label={entry.title}
                      imageUrl={entry.cover_url}
                      key={entry.id}
                      onChange={handleBookCheck}
                    />
                  ))
              }
              </div>
            </div>
          ))
        }
        {
          this.state.using === 'Not using' ?
            <div className="big-label">
              <LabeledInput
                name="num_students"
                type="number"
                label="How many students do you teach each semester?"
                helper="Include sections taught by TAs that you oversee."
                min="1"
                max="999"
              />
            </div> :
            this.state.selectedBooks.map((b) => {
              const title = this.state.bookInfo
                .find((entry) => entry.salesforce_abbreviation === b)
                .title;

              return (
                <div className="big-label" key={b}>
                  <LabeledInput
                    name="num_students"
                    type="number"
                    label={`How many students are using ${title} each semester?`}
                    helper="Include sections taught by TAs that you oversee."
                    min="1"
                    max="999"
                  />
                </div>
              );
            })
        }
        <div className="checkboxes">
          <label>
            <input
              type="checkbox"
              defaultChecked
            />
            <span>Keep me informed about OpenStax.</span>
          </label>
          <label>
            <input
              type="checkbox"
              checked={this.state.agreeToTerms}
              onChange={toggleAgreeToTerms}
            />
            <span>I agree to the <a href="">Terms of Use</a> and
            the <a href="">Privacy Policy</a>.</span>
          </label>
        </div>
        <div className="button-zone">
          <button type="button"
            className="secondary"
            onClick={prevPage}
          >Back</button>
          <button type="submit"
            className="primary"
            disabled={submitDisabled()}
          >Create account</button>
        </div>
      </div>
    </div>
  }

}
