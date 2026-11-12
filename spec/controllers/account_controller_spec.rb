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
    expect(response.body).to include('Verified instructor')
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
    expect(response.body).to include('First book reported')
    expect(response.body).to include('Report this term’s classes to keep your impact current')
    expect(response.body).to include('Grows with the books you’ve reported')
    expect(response.body).not_to include('students from your')
    expect(response.body).not_to include('Report a book you use to get there')
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

  describe 'the overview layout' do
    let(:year) { SchoolYear.current }

    before do
      allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
        { subject_name: 'Science', books: [{ title: 'College Physics', salesforce_abbreviation: 'Physics' }] }
      ])
    end

    def save_book(title, created_at: Time.current)
      book = Book.create!(book_uuid: SecureRandom.uuid, title: title)
      UserBook.create!(user: user, book: book, created_at: created_at)
    end

    def answer(title, status)
      AdoptionReport.create!(user: user, book_title: title, school_year: year, status: status, source: 'books_status')
    end

    def section(html)
      html[/<section class="account-term-books".*?<\/section>/m].to_s
    end

    it 'orders the page: status, books this term, impact, LMS question, quick actions' do
      user.update!(faculty_status: :pending_sheerid, is_profile_complete: true)
      save_book('College Physics')

      get :overview

      ids = ['id="verification-callout"', 'id="overview-books"', 'id="overview-impact"',
             'id="lms-question-card"', 'id="quick-actions-heading"'].map { |marker| response.body.index(marker) }
      expect(ids).to all(be_present)
      expect(ids).to eq(ids.sort)
    end

    it 'lists each answer for this school year' do
      save_book('Reported Book', created_at: 1.minute.ago)
      save_book('Considering Book', created_at: 2.minutes.ago)
      save_book('Browsing Book', created_at: 3.minutes.ago)
      save_book('Not Using Book', created_at: 4.minutes.ago)
      answer('Reported Book', 'using')
      answer('Considering Book', 'considering')
      answer('Browsing Book', 'browsing')
      answer('Not Using Book', 'not_using')

      get :overview

      html = section(response.body)
      expect(html).to include('Your books this term')
      expect(html).to include("Reported for #{year}")
      expect(html).to include('Considering it')
      expect(html).to include('Just looking')
      expect(html).to include('Not teaching with it this year')
      expect(html).not_to include('Tell us where you are with it')
      expect(html.scan('account-term-books__item').size).to eq(4)
      expect(html).to include('Manage your books')
    end

    it 'counts a confirmed adoption as reported' do
      book = Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics', salesforce_book_id: 'a0Book000001')
      UserBook.create!(user: user, book: book)
      Adoption.create!(salesforce_id: SecureRandom.hex(9), user: user, salesforce_book_id: 'a0Book000001',
                       confirmation_type: 'OpenStax Confirmed Adoption', rollover_status: false,
                       students: 10, school_year: year, base_year: SchoolYear.base_year_for(Time.zone.today))

      get :overview

      expect(section(response.body)).to include("Reported for #{year}")
    end

    it 'offers a plain link when a book has no answer, and no modal trigger' do
      save_book('College Physics')

      get :overview

      html = section(response.body)
      expect(html).to include('Tell us where you are with it')
      expect(html).to include(%(href="#{account_books_path}"))
      expect(html).not_to include('data-report-adoption-trigger')
    end

    it 'shows the four newest books and a count link when there are more' do
      5.times { |i| save_book("Book #{i}", created_at: i.minutes.ago) }

      get :overview

      html = section(response.body)
      expect(html.scan('account-term-books__item').size).to eq(4)
      expect(html).to include('Book 0', 'Book 3')
      expect(html).not_to include('Book 4')
      expect(html).to include('See all your books (5)')
      expect(html).not_to include('Manage your books')
    end

    it 'sizes and lazy-loads covers' do
      book = Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics', cover_url: 'https://example.com/c.png')
      UserBook.create!(user: user, book: book)

      get :overview

      img = section(response.body)[/<img[^>]*>/]
      expect(img).to include('width="48"', 'height="48"', 'loading="lazy"')
    end

    it 'invites saving books when there are none' do
      get :overview

      html = section(response.body)
      expect(html).to include('Save the books you use or are thinking about')
      expect(html).to include('Save books')
      expect(html).not_to include('account-term-books__item')
    end

    it 'is replaced by the check-in card while a check-in is due' do
      user.update_column(:created_at, 2.years.ago)
      save_book('College Physics')

      get :overview

      expect(response.body).to include('id="annual-check-in"')
      expect(response.body).not_to include('id="overview-books"')
    end

    it 'drops the account table, the status section and the newsletter action' do
      get :overview

      ['Account details', 'Account health', 'Manage details in', 'OpenStax status', 'Keep in touch',
       'status.openstax.org', 'openstax.org/newsletters', 'account-facts'].each do |text|
        expect(response.body).not_to include(text)
      end
      expect(response.body).to include('Quick actions')
      expect(response.body.scan('account-actions__item').size).to eq(4)
    end

    it 'puts the status and newsletter links on the Support page' do
      get :support

      expect(response.body).to include('Check whether OpenStax services are running')
      expect(response.body).to include('href="https://status.openstax.org"')
      expect(response.body).to include('Get OpenStax news and updates')
      expect(response.body).to include('href="https://openstax.org/newsletters"')
    end

    describe 'profile completeness' do
      it 'shows a strip while the profile is incomplete, without repeating prompts the page already makes' do
        user.update!(school: nil, self_reported_school: nil)

        get :overview

        html = response.body
        expect(html).to include('account-profile-strip')
        expect(html).to include('Your profile is')
        expect(html).to include('Add your school')
        expect(html).not_to include('Save a book')
        expect(Nokogiri::HTML(html).css('.account-profile-strip').text).not_to include('Report a book you use')
        expect(html).not_to include('Answer the LMS question')
      end

      it 'is left out when everything still to do is already asked for elsewhere on the page' do
        user.update!(school: FactoryBot.create(:school))

        get :overview

        expect(response.body).not_to include('account-profile-strip')
      end

      it 'is hidden at 100%' do
        user.update!(school: FactoryBot.create(:school), lms_used: 'canvas')
        save_book('College Physics')
        answer('College Physics', 'using')

        get :overview

        expect(response.body).not_to include('account-profile-strip')
        expect(response.body).not_to include('Your profile is')
      end
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

  describe 'the "Books you\'re interested in" section' do
    before do
      allow(Settings::Salesforce).to receive(:push_book_interest_enabled).and_return(true)
      allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
        { subject_name: 'Science', books: [
          { title: 'Biology 2e', salesforce_abbreviation: 'Biology' },
          { title: 'College Physics', salesforce_abbreviation: 'College Physics' },
          { title: 'Astronomy 2e', salesforce_abbreviation: 'Astronomy' }
        ] }
      ])
    end

    it 'is hidden while the Salesforce push is off' do
      allow(Settings::Salesforce).to receive(:push_book_interest_enabled).and_return(false)
      user.update!(which_books: 'Biology')

      get :books

      expect(response.body).not_to include('id="book-interests"')
    end

    it 'lists each book by catalog title with a Remove control that names it' do
      user.update!(which_books: 'Biology;College Physics')

      get :books

      expect(response.body).to include("Books you're interested in").or include('Books you&#39;re interested in')
      expect(response.body).to include('Biology 2e')
      expect(response.body).to include('Remove<span class="sr-only"> Biology 2e from your interests</span>')
      expect(response.body).to include('Remove<span class="sr-only"> College Physics from your interests</span>')
      expect(response.body).to include('name="abbreviation" value="Biology"')
    end

    it 'falls back to the raw value for a book the catalog does not know' do
      user.update!(which_books: 'Retired Title')

      get :books

      expect(response.body).to include('Retired Title')
    end

    it 'offers only the books not already listed' do
      user.update!(which_books: 'Biology')

      get :books

      select = response.body[/<select id="book-interest-add".*?<\/select>/m]
      expect(select).to include('value="Astronomy"').and include('value="College Physics"')
      expect(select).not_to include('value="Biology"')
    end

    it 'shows a friendly empty state with the add control' do
      get :books

      expect(response.body).to include(CGI.escapeHTML("You haven't added any books yet."))
      expect(response.body).to include('book-interest-add')
      expect(response.body).not_to include('book-interests__list')
    end

    it 'escapes titles' do
      user.update!(which_books: '<b>x</b>')

      get :books

      expect(response.body).not_to include('<b>x</b>')
      expect(response.body).to include('&lt;b&gt;x&lt;/b&gt;')
    end

    it 'is not shown to students or lifelong learners' do
      %i[student self_learner].each do |role|
        user.update!(role: role, which_books: 'Biology')

        get :books

        expect(response.body).not_to include('book-interests')
      end
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

    it 'drops the LMS item from the completeness strip once answered' do
      user.update!(lms_used: 'moodle')

      get :overview

      expect(response.body).not_to include('Answer the LMS question')
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
      expect(response.body).to include('Welcome to OpenStax, Jordan')
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
      expect(response.body).to include('Welcome to OpenStax, Lee')
      expect(response.body).to include('Astronomy 2e')
      expect(response.body).to include('https://openstax.org/subjects')
      expect(response.body).to include(account_profile_path)
      expect(response.body).to include(account_security_path)
    end

    it 'shows no instructor, verification, LMS or book-reporting content' do
      get :overview

      ['nstructor', 'erification', 'Verified', 'Finish signing up', 'LMS',
       'Report a book you use', 'Self Learner', 'Impact'].each do |text|
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

    it 'shows the books-this-term section in neutral wording' do
      get :overview

      expect(response.body).to include('Your books this term')
      expect(response.body).to include('Save the books you use or are thinking about')
    end

    it 'keeps usage reporting and the impact page' do
      get :overview
      expect(response.body).to include('Report a book you use')

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

      expect(response.body).to include('Your verification is in progress')
      expect(response.body).to include('Verification pending')
    end

    it 'sees the verified badge once confirmed' do
      instructor.update!(faculty_status: :confirmed_faculty)
      get :overview
      expect(response.body).to include('Verified instructor')
    end
  end

  describe 'overview status by account state' do
    let(:email) { user.email_addresses.last&.value }

    def body_text
      Nokogiri::HTML(response.body).css('.account-overview__header, .account-callout').text.squish
    end

    def overview_as(**attrs)
      user.update!(attrs)
      get :overview
      expect(response).to have_http_status(:ok)
    end

    it 'welcomes a brand new account and does not say all set' do
      user.update_columns(created_at: Time.current, last_signed_in_at: nil, last_seen_at: nil)
      overview_as(faculty_status: :incomplete_signup, is_profile_complete: false, first_name: 'Rita')

      expect(body_text).to include('Welcome to OpenStax, Rita')
      expect(body_text).not_to include('Welcome back')
      expect(body_text).to include('Finish signing up')
      expect(response.body).to include('id="complete-signup-callout"')
      expect(response.body).not_to include('All set')
    end

    it 'welcomes back a returning verified instructor with no callout' do
      user.update_columns(created_at: 90.days.ago)
      overview_as(faculty_status: :confirmed_faculty, is_profile_complete: true, which_books: 'Biology 2e',
                  how_many_students: 20, self_reported_school: 'Rice University')

      expect(body_text).to include('Welcome back, Rita')
      expect(body_text).to include('Verified instructor')
      expect(response.body).not_to include('class="account-callout"')
    end

    it 'tells a pending CS user what the signup screen told them, with no verify button' do
      overview_as(faculty_status: :pending_faculty, is_educator_pending_cs_verification: true,
                  is_profile_complete: true)

      expect(body_text).to include('Verification pending')
      expect(body_text).to include("We're processing your request")
      expect(body_text).to include('3-4 business days')
      expect(body_text).not_to include('Verify now')
      expect(response.body).to include(account_support_path)
      expect(response.body).not_to include('account-badge--verified')
    end

    it 'shows SheerID progress without asking for anything' do
      overview_as(faculty_status: :pending_sheerid, is_profile_complete: true)

      expect(body_text).to include('Your verification is in progress')
      expect(response.body).not_to include('account-callout__button--primary')
    end

    it 'offers Verify another way after a SheerID rejection before step 4' do
      overview_as(faculty_status: :rejected_by_sheerid, is_profile_complete: false)

      expect(body_text).to include('Verify another way')
      expect(response.body).to include(educator_cs_verification_form_path)
    end

    it 'sends an incomplete signup to the SheerID step' do
      overview_as(faculty_status: :incomplete_signup, is_profile_complete: false)

      expect(response.body).to include(educator_sheerid_form_path)
      expect(body_text).to include('Finish signing up')
      expect(body_text).not_to include('Verified')
    end

    it 'treats a rejected user respectfully and points to help' do
      overview_as(faculty_status: :rejected_faculty, is_profile_complete: true)

      expect(body_text).to include("We couldn't confirm your instructor status")
      expect(body_text).to include('Instructor access not active')
      expect(response.body).to include(OverviewStatus::REJECTED_HELP_URL)
      expect(response.body).not_to include('account-badge--verified')
    end

    it 'shows staff their role and no instructor verification wording' do
      overview_as(role: :librarian, other_role_name: 'Librarian', faculty_status: :incomplete_signup,
                  is_profile_complete: true)

      expect(body_text).to include('Librarian')
      expect(body_text).not_to match(/verif|instructor/i)
      expect(response.body).not_to include('class="account-callout"')
    end

    it 'drops the comma when there is no first name' do
      user.update_columns(created_at: 90.days.ago, first_name: '')
      overview_as(faculty_status: :confirmed_faculty, is_profile_complete: true)

      expect(Nokogiri::HTML(response.body).at_css('h1.account-overview__title').text.squish).to eq('Welcome back')
    end
  end
end
