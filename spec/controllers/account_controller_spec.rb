require 'rails_helper'

RSpec.describe AccountController, type: :controller do
  render_views

  # These specs predate role-based branching on #overview and are about the
  # instructor experience specifically, so pin the role explicitly rather
  # than relying on the factory default (which is :student — see the
  # "student account" describe block below for that experience).
  let(:user) { FactoryBot.create(:user, :terms_agreed, role: :instructor, first_name: 'Rita', last_name: 'Instructor') }

  before { controller.sign_in! user }

  %i[overview profile security books support].each do |page|
    it "renders the #{page} page" do
      get page
      expect(response).to have_http_status(:ok)
    end
  end

  it 'shows status badges on the overview for a verified instructor with a school' do
    school = FactoryBot.create(:school, name: 'Rice University')
    user.update!(faculty_status: :confirmed_faculty, school: school)

    get :overview

    expect(response.body).to include('account-badge--verified')
    expect(response.body).to include('Verified educator')
    expect(response.body).to include('Rice University')
  end

  it 'omits the verified badge for unverified users' do
    get :overview
    expect(response.body).not_to include('account-badge--verified')
  end

  it 'renders the impact page for both views' do
    get :impact
    expect(response).to have_http_status(:ok)

    get :impact, params: { view: 'lifetime' }
    expect(response).to have_http_status(:ok)
  end

  it 'renders impact stats from the user adoptions' do
    # Book record not required for this example
    Adoption.create!(
      salesforce_id: 'SF_ADOPTION_1',
      user: user,
      confirmation_type: 'OpenStax Confirmed Adoption',
      rollover_status: false,
      school_year: SchoolYear.current,
      students: 30,
      savings: 3000,
      salesforce_book_id: nil
    )

    get :impact
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('30')
  end

  it 'renders the milestone ladder on the impact page once the user has adoptions' do
    Adoption.create!(
      salesforce_id: 'SF_ADOPTION_MILESTONE',
      user: user,
      confirmation_type: 'OpenStax Confirmed Adoption',
      rollover_status: false,
      base_year: 2024,
      students: 150,
      savings: 12_000,
      salesforce_book_id: nil
    )

    get :impact

    expect(response.body).to include('Milestones')
    expect(response.body).to include('First adoption')
    expect(response.body).to include('Report this term’s classes to keep your impact current')
    expect(response.body).to include('Grows with your confirmed adoptions')
    expect(response.body).not_to include('students from your')
    expect(response.body).not_to include('Report an adoption to get there')
  end

  describe 'a report held for review on the impact page' do
    def report_for(title, students)
      AdoptionReport.create!(user: user, book_title: title, salesforce_book_name: title, school_year: SchoolYear.current,
                             source: 'books_modal', status: 'using', students: students)
    end

    it 'tells the instructor we are checking it, only on that row, with no alarm in the wording' do
      report_for('College Physics', 4000)
      report_for('Biology 2e', 40)

      get :impact

      expect(response.body.scan("We're checking this one").size + response.body.scan('We&#39;re checking this one').size).to eq 1
      expect(response.body).to include('Pending, saved')
      expect(response.body).not_to match(/suspicious|too (high|large)|fraud|verify your/i)
    end

    it 'goes back to the normal chip once approved' do
      report_for('College Physics', 4000).update!(review_status: 'approved')

      get :impact

      expect(response.body).not_to include('checking this one')
      expect(response.body).to include('Pending, saved')
    end
  end

  describe 'pending reports on the impact page' do
    before do
      Adoption.create!(salesforce_id: 'SF_PENDING_BASE', user: user, confirmation_type: 'OpenStax Confirmed Adoption',
                       rollover_status: false, school_year: SchoolYear.current, students: 415, salesforce_book_id: nil)
      AdoptionReport.create!(user: user, book_title: 'College Physics', salesforce_book_name: 'College Physics',
                             school_year: SchoolYear.current, source: 'books_modal', status: 'using', students: 120)
    end

    it 'labels pending students apart from the confirmed total and for screen readers' do
      get :impact

      expect(response.body).to include('+120 pending')
      expect(response.body).to include('Plus 120 students pending confirmation, not yet in the total.')
      expect(response.body).not_to include('to your 500-student milestone')
    end

    it 'compares books reported this year with saved books' do
      UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics'))
      UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e'))

      get :impact

      expect(response.body).to include('You’ve told us about 1 of your 2 saved books this year')
    end
  end

  it 'asks for a first report in the locked state without a contextual second prompt' do
    get :impact

    expect(response.body).to include('Once you report, this page shows the students you reach')
    expect(response.body).not_to include('impact-next-prompt')
  end

  it 'omits the milestone ladder when the user has never had an adoption' do
    get :impact
    expect(response.body).not_to include('Next milestone')
  end

  describe 'the annual check-in card on Overview' do
    let(:book) { Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics') }

    before do
      user.update_column(:created_at, 2.years.ago)
      UserBook.create!(user: user, book: book)
    end

    it 'renders for a due instructor with prefilled rows and never redirects other pages' do
      last_year = SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1)
      AdoptionReport.create!(user: user, book_title: 'College Physics', school_year: last_year,
                             source: 'books_modal', students: 75)

      get :overview

      expect(response.body).to include('id="annual-check-in"')
      expect(response.body).to include('Are you teaching with these books in')
      expect(response.body).to include('value="75"')
      expect(response.body).to include('Remind me later')
      expect(response.body).not_to include('checked')

      %i[profile books security impact support].each do |page|
        get page
        expect(response).to have_http_status(:ok)
      end
    end

    it 'is absent once snoozed' do
      user.update!(check_in_dismissed_at: 1.day.ago)

      get :overview

      expect(response.body).not_to include('id="annual-check-in"')
    end
  end

  describe 'the "Your impact" card on Overview' do
    before do
      allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
        { subject_name: 'Science', books: [{ title: 'College Physics', salesforce_abbreviation: 'Physics' }] }
      ])
    end

    def confirmed_adoption(students:, savings: nil, base_year: SchoolYear.base_year_for(Time.zone.today) - 1)
      Adoption.create!(salesforce_id: SecureRandom.hex(9), user: user, confirmation_type: 'OpenStax Confirmed Adoption', rollover_status: false,
                       students: students, savings: savings, base_year: base_year,
                       school_year: SchoolYear.label_for(base_year))
    end

    it 'invites a first report when there is nothing yet, with the reason and the trigger' do
      get :overview

      expect(response.body).to include('id="overview-impact"')
      expect(response.body).to include('Your impact starts here')
      expect(response.body).to include('secure the funding that keeps OpenStax free')
      expect(response.body).to include('data-report-adoption-trigger')
      expect(response.body).not_to include('account-impact-card__stats')
    end

    it 'shows lifetime numbers, saved books reported this year, the reason and a link to the Impact tab' do
      confirmed_adoption(students: 415, savings: 41_500)
      UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics'))
      UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e'))
      AdoptionReport.create!(user: user, book_title: 'Biology 2e', status: 'using', source: 'books_modal',
                             school_year: SchoolYear.current)

      get :overview

      expect(response.body).to include('Students reached')
      expect(response.body).to include('415')
      expect(response.body).to include('$41,500')
      expect(response.body).to include('Years with OpenStax')
      expect(response.body).to include(CGI.escapeHTML("You've told us about 1 of your 2 saved books for #{SchoolYear.current}"))
      expect(response.body).not_to include('milestone')
      expect(response.body).to include('show funders that free books reach real students')
      expect(response.body).to include(%(href="#{account_impact_path}"))
      expect(response.body).not_to include('Your impact starts here')
    end

    it 'shows reports Salesforce has not confirmed yet as pending, without moving the confirmed totals' do
      confirmed_adoption(students: 415)
      AdoptionReport.create!(user: user, book_title: 'College Physics', salesforce_book_name: 'Physics',
                             school_year: SchoolYear.current, status: 'using', students: 120,
                             how_using: AdoptionReport::HOW_USING_OPTIONS.first, source: 'books_modal')

      get :overview

      expect(response.body).to include('+120 students from 1 book, pending.')
      expect(response.body).to include('415')
      expect(response.body).not_to include('milestone')
    end

    it 'sits after the check-in card' do
      user.update_column(:created_at, 2.years.ago)
      UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics'))

      get :overview

      expect(response.body.index('id="annual-check-in"')).to be < response.body.index('id="overview-impact"')
    end

    it 'words the quick action differently from the card' do
      get :overview

      expect(response.body).to include('Count your students')
      expect(response.body).to include('Count my students')
    end
  end

  describe 'the check-in streak copy' do
    let(:book) { Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics') }

    before do
      user.update_column(:created_at, 3.years.ago)
      UserBook.create!(user: user, book: book)
    end

    def report_for(offset)
      AdoptionReport.create!(user: user, book_title: 'College Physics', status: 'using', source: 'books_modal',
                             school_year: SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - offset))
    end

    it 'celebrates the year being confirmed and carries one reason line' do
      report_for(1)
      report_for(2)

      get :overview

      expect(response.body).to include('Year 3 with OpenStax.')
      expect(response.body).to include('Thank you for sticking with us.')
      expect(response.body).to include('Every report helps fund new free titles.')
    end

    it 'offers a grace line, not a threat, after a missed year' do
      report_for(3)

      get :overview

      expect(response.body).to include('Missed a year? Pick up where you left off.')
      expect(response.body).not_to include('Year 1 with OpenStax')
    end
  end

  describe 'the Books tab' do
    before do
      allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
        { subject_name: 'Science', books: [
          { title: 'College Physics', salesforce_abbreviation: 'Physics' },
          { title: 'Biology 2e', salesforce_abbreviation: 'Bio 2e' }
        ] }
      ])
      ['College Physics', 'Biology 2e', 'Mystery Book'].each do |title|
        UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: title))
      end
      AdoptionReport.create!(user: user, book_title: 'Biology 2e', status: 'using', source: 'books_modal',
                             school_year: SchoolYear.current)
    end

    it 'offers a preselecting trigger only for catalog books without a report this year' do
      get :books

      expect(response.body).to include('data-report-adoption-book="Physics"')
      expect(response.body).not_to include('data-report-adoption-book="Bio 2e"')
      expect(response.body.scan('data-report-adoption-book=').size).to eq(1)
      expect(response.body).to include('id="reportAdoptionModal"')
    end

    it 'gives each unanswered book a three-way choice, and Mystery Book only the two local ones' do
      get :books

      expect(response.body).to include('Where are you with College Physics this term?')
      expect(response.body).to include('Where are you with Mystery Book this term?')
      expect(response.body.scan('Teaching with it').size).to eq(1)
      expect(response.body.scan(/>\s*Considering it\s*</).size).to eq(2)
      expect(response.body.scan(/>\s*Just looking\s*</).size).to eq(2)
      expect(response.body).not_to include('Where are you with Biology 2e this term?')
      expect(response.body).to include('Reported for')
    end

    it 'shows a quiet chip and a Change control for a considering, browsing or not-using answer' do
      { 'College Physics' => 'considering', 'Mystery Book' => 'browsing' }.each do |title, status|
        AdoptionReport.create!(user: user, book_title: title, status: status, source: 'books_status',
                               school_year: SchoolYear.current)
      end

      get :books

      expect(response.body).to include('account-chip">Considering it<')
      expect(response.body).to include('account-chip">Just looking<')
      expect(response.body.scan('book-status__change').size).to eq(2)
      expect(response.body).to include('aria-pressed="true"')
    end

    it 'words a not-using check-in answer as not teaching with it this year' do
      AdoptionReport.create!(user: user, book_title: 'College Physics', status: 'not_using', source: 'check_in',
                             school_year: SchoolYear.current)

      get :books

      expect(response.body).to include('Not teaching with it this year')
    end
  end

  describe 'the LMS question card on Overview' do
    it 'shows the card for a user who has neither answered nor dismissed it' do
      get :overview
      expect(response.body).to include('lms-question-card')
      expect(response.body).to include('Do you use a learning management system (LMS)?')
    end

    it 'hides the card once the user has answered' do
      user.update!(lms_used: 'canvas')

      get :overview

      expect(response.body).not_to include('Do you use a learning management system (LMS)?')
    end

    it 'hides the card once the user has dismissed it' do
      user.update!(lms_prompt_dismissed_at: Time.current)

      get :overview

      expect(response.body).not_to include('Do you use a learning management system (LMS)?')
    end

    it 're-shows a dismissed card when jumped to via ?show_lms=1' do
      user.update!(lms_prompt_dismissed_at: Time.current)

      get :overview, params: { show_lms: '1' }

      expect(response.body).to include('Do you use a learning management system (LMS)?')
    end

    it 'shows the completeness chip for LMS as done once answered' do
      user.update!(lms_used: 'moodle')

      get :overview

      expect(response.body).to include('account-completeness__chip--done')
      expect(response.body).to include('Answer LMS question')
    end
  end

  describe 'the profile-nudge banner on Overview' do
    before do
      user.update!(
        is_newflow: true,
        is_profile_complete: false,
        sheerid_verification_id: 'a-verification-id',
        profile_nudge_redirected_at: 1.day.ago
      )
    end

    it 'shows the banner and logs it once' do
      get :overview
      expect(assigns(:show_profile_nudge_banner)).to be(true)
      expect(response.body).to include(I18n.t(:"profile_nudge_banner.heading"))
      expect(SecurityLog.where(user: user, event_type: :profile_nudge_banner_shown).count).to eq(1)

      get :overview
      expect(SecurityLog.where(user: user, event_type: :profile_nudge_banner_shown).count).to eq(1)
    end

    it 'does not show the banner once dismissed for the session' do
      session[:profile_nudge_dismissed] = true
      get :overview
      expect(assigns(:show_profile_nudge_banner)).to be_falsey
      expect(response.body).not_to include(I18n.t(:"profile_nudge_banner.heading"))
    end

    it 'does not show the banner once the profile is complete' do
      user.update!(is_profile_complete: true)
      get :overview
      expect(assigns(:show_profile_nudge_banner)).to be_falsey
    end
  end

  describe 'student account overview' do
    let(:student) { FactoryBot.create(:user, :terms_agreed, role: :student, first_name: 'Jordan') }

    before { controller.sign_in! student }

    it 'renders the student overview instead of the instructor overview' do
      get :overview

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Welcome back, Jordan')
      expect(response.body).to include('Tell us who teaches your class')
      expect(response.body).to include('account-badge--student')
      expect(response.body).not_to include('Verified educator')
    end

    it 'shows the "school verified" pill only when the student has a school' do
      student.update!(school: nil)
      get :overview
      expect(response.body).not_to include('School verified')

      student.update!(school: FactoryBot.create(:school, name: 'Rice University'))
      get :overview
      expect(response.body).to include('School verified')
    end

    it "lists the student's saved books with a read-online link" do
      book = Book.create!(
        book_uuid: SecureRandom.uuid, title: 'Biology 2e',
        html_url: 'https://openstax.org/details/books/biology-2e'
      )
      UserBook.create!(user: student, book: book)

      get :overview

      expect(response.body).to include('Biology 2e')
      expect(response.body).to include('https://openstax.org/details/books/biology-2e')
    end

    it 'shows unverified instructor claims the student has already made' do
      FactoryBot.create(:instructor_connection, student: student, instructor_name: 'Sarah Delgado',
                                                 school_name: 'Rice University')

      get :overview

      expect(response.body).to include('Sarah Delgado')
      expect(response.body).to include('account-student-overview__unverified-chip">Submitted')
    end

    it 'still renders every other account page for a student' do
      %i[profile security books impact support].each do |page|
        get page
        expect(response).to have_http_status(:ok)
      end
    end

    it 'hides the instructor-only Books and Impact tabs from the student nav' do
      get :overview

      expect(response.body).not_to include('My OpenStax Impact')
      expect(response.body).not_to include('My OpenStax Books')
      expect(response.body).to include('Profile')
    end
  end

  describe 'nav items by role' do
    def nav_labels
      response.body.scan(%r{<nav class="account-shell__nav"[^>]*>.*?</nav>}m).first.scan(%r{>([^<]+)</a>}).flatten
    end

    {
      instructor: ['Account overview', 'Profile', 'Security', 'My OpenStax Books', 'My OpenStax Impact', 'Support'],
      student: ['Account overview', 'Profile', 'Security', 'Support'],
      self_learner: ['Account overview', 'Profile', 'Security', 'My OpenStax Books', 'Support'],
      librarian: ['Account overview', 'Profile', 'Security', 'My OpenStax Books', 'My OpenStax Impact', 'Support']
    }.each do |role, labels|
      it "shows #{labels.size} tabs for #{role}" do
        controller.sign_in! FactoryBot.create(:user, :terms_agreed, role: role, is_profile_complete: role == :librarian)
        get :overview
        expect(nav_labels).to eq(labels)
      end
    end
  end

  describe 'lifelong learner account' do
    let(:learner) { FactoryBot.create(:user, :terms_agreed, role: :self_learner, first_name: 'Lee') }

    before { controller.sign_in! learner }

    it 'renders a learner overview with saved books and links' do
      book = Book.create!(book_uuid: SecureRandom.uuid, title: 'Astronomy 2e',
                          html_url: 'https://openstax.org/details/books/astronomy-2e')
      UserBook.create!(user: learner, book: book)

      get :overview

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Welcome, Lee')
      expect(response.body).to include('Astronomy 2e')
      expect(response.body).to include('https://openstax.org/subjects')
      expect(response.body).to include(account_profile_path)
      expect(response.body).to include(account_security_path)
    end

    it 'shows no instructor, verification, LMS or adoption content' do
      get :overview

      ['nstructor', 'erification', 'Verified', 'Finish signing up', 'LMS',
       'Report an adoption', 'Self Learner', 'Impact'].each do |text|
        expect(response.body).not_to include(text)
      end
    end

    it 'redirects the impact page to the overview' do
      get :impact
      expect(response).to redirect_to(account_overview_path)
    end

    it 'still renders the books page' do
      get :books
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'staff account' do
    let(:staff) do
      FactoryBot.create(:user, :terms_agreed, role: :librarian, other_role_name: 'Librarian',
                                              faculty_status: :incomplete_signup, is_profile_complete: true,
                                              first_name: 'Sam')
    end

    before { controller.sign_in! staff }

    it 'omits the signup and verification callouts and instructor wording' do
      get :overview

      expect(response).to have_http_status(:ok)
      ['Finish signing up', 'Complete your instructor profile', 'Complete instructor verification',
       'Verified educator', 'Pending verification', 'Instructor status', 'signed in as an instructor',
       'Finish telling us about your teaching'].each do |text|
        expect(response.body).not_to include(text)
      end
    end

    it 'shows the label they gave, falling back to the role' do
      staff.update!(role: :administrator, other_role_name: 'Dean of students')
      get :overview
      expect(response.body).to include('Dean of students')

      staff.update!(other_role_name: nil)
      get :overview
      expect(response.body).to include('Administrator')
    end

    it 'keeps usage reporting and the impact page' do
      get :overview
      expect(response.body).to include('Report an adoption')

      get :impact
      expect(response).to have_http_status(:ok)
    end

    it 'still shows the signup callout while the profile is incomplete' do
      staff.update!(is_profile_complete: false)
      get :overview
      expect(response.body).to include('Finish signing up')
    end
  end

  describe 'instructor who chose administrator at step 4' do
    let(:instructor) do
      FactoryBot.create(:user, :terms_agreed, role: :administrator, other_role_name: 'Dean',
                                              faculty_status: :pending_sheerid, is_profile_complete: true)
    end

    before { controller.sign_in! instructor }

    it 'still sees the verification callout and status' do
      get :overview

      expect(response.body).to include('Complete instructor verification')
      expect(response.body).to include('Instructor status')
      expect(response.body).to include('signed in as an instructor').or include('Access your teaching tools')
    end

    it 'sees the verified badge once confirmed' do
      instructor.update!(faculty_status: :confirmed_faculty)
      get :overview
      expect(response.body).to include('Verified educator')
    end
  end
end
