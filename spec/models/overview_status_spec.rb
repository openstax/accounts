require 'rails_helper'

RSpec.describe OverviewStatus, type: :model do
  let(:user) do
    FactoryBot.create(:user, :terms_agreed, role: :instructor, first_name: 'Rita', is_newflow: true, school: nil,
                                            created_at: 60.days.ago, last_signed_in_at: 1.day.ago)
  end

  def status_for(**attrs)
    user.update!(attrs)
    described_class.new(user)
  end

  describe '#greeting' do
    it 'welcomes an account made today' do
      user.update_columns(created_at: Time.current, last_signed_in_at: Time.current, last_seen_at: nil)
      expect(described_class.new(user).greeting).to eq('Welcome to OpenStax, Rita')
    end

    it 'welcomes back someone who returned on a later day within the first two weeks' do
      user.update_columns(created_at: 3.days.ago, last_signed_in_at: 1.hour.ago)
      expect(described_class.new(user).greeting).to eq('Welcome back, Rita')
    end

    it 'counts a later last_seen_at as a return too' do
      user.update_columns(created_at: 3.days.ago, last_signed_in_at: 3.days.ago, last_seen_at: 1.hour.ago)
      expect(described_class.new(user).greeting).to eq('Welcome back, Rita')
    end

    it 'keeps welcoming a never-returned account for up to 14 days, then says welcome back' do
      user.update_columns(created_at: 10.days.ago, last_signed_in_at: 10.days.ago, last_seen_at: nil)
      expect(described_class.new(user).greeting).to eq('Welcome to OpenStax, Rita')

      user.update_columns(created_at: 15.days.ago, last_signed_in_at: 15.days.ago)
      expect(described_class.new(user).greeting).to eq('Welcome back, Rita')
    end

    it 'drops the comma without a first name' do
      user.update_columns(first_name: '', created_at: Time.current, last_signed_in_at: nil)
      expect(described_class.new(user).greeting).to eq('Welcome to OpenStax')

      user.update_columns(created_at: 60.days.ago)
      expect(described_class.new(user).greeting).to eq('Welcome back')
    end
  end

  # state => [attributes, badge, subtitle fragment, callout id, callout title, primary path]
  describe 'each account state' do
    let(:support_path) { Rails.application.routes.url_helpers.account_support_path }
    let(:routes) { Rails.application.routes.url_helpers }

    it 'verified instructor with a school' do
      s = status_for(faculty_status: :confirmed_faculty, is_profile_complete: true, which_books: 'Biology 2e',
                     how_many_students: 30, self_reported_school: 'Rice University')
      expect(s.state).to eq(:verified)
      expect(s.badges.map(&:label)).to eq(['Verified instructor'])
      expect(s.badges.first.tone).to eq(:verified)
      expect(s.subtitle).to include('<strong>Rice University</strong>')
      expect(s.add_school_link?).to be(false)
      expect(s.callout).to be_nil
    end

    it 'verified instructor with a skipped profile is nudged to add details' do
      s = status_for(faculty_status: :confirmed_faculty, is_profile_complete: true)
      expect(s.callout.id).to eq('enrich-profile-callout')
      expect(s.callout.primary.path).to eq(routes.educator_profile_form_path)
      expect(s.add_school_link?).to be(true)
    end

    it 'verified instructor mid step 4 gets the profile nudge, worded for a verified user' do
      s = status_for(faculty_status: :confirmed_faculty, is_profile_complete: false)
      callout = s.callout(show_profile_nudge: true)
      expect(callout).to be_nudge
      expect(callout.paragraphs.first).to include("You're verified")
    end

    it 'pending CS review repeats the screen the user saw and offers no action button' do
      s = status_for(faculty_status: :pending_faculty, is_educator_pending_cs_verification: true,
                     is_profile_complete: true)
      email = user.email_addresses.last&.value
      expect(s.state).to eq(:pending_review)
      expect(s.badges.map(&:label)).to eq(['Verification pending'])
      expect(s.subtitle).to include('reviewing your request')
      expect(s.callout.title).to eq("We're processing your request")
      expect(s.callout.paragraphs.join(' ')).to include('3-4 business days')
      expect(s.callout.paragraphs.join(' ')).to include('except those that require instructor verification')
      expect(s.callout.paragraphs.join(' ')).to include(email) if email
      expect(s.callout.primary).to be_nil
      expect(s.callout.secondary.path).to eq(support_path)
    end

    it 'a finished profile with no SheerID outcome is treated as pending review' do
      s = status_for(faculty_status: :incomplete_signup, is_profile_complete: true)
      expect(s.state).to eq(:pending_review)
    end

    it 'SheerID still deciding after step 4 says so without asking for anything' do
      s = status_for(faculty_status: :pending_sheerid, is_profile_complete: true)
      expect(s.state).to eq(:checking)
      expect(s.badges.map(&:label)).to eq(['Verification pending'])
      expect(s.callout.title).to eq('Your verification is in progress')
      expect(s.callout.primary).to be_nil
    end

    it 'SheerID pending before step 4 points at step 4' do
      s = status_for(faculty_status: :pending_sheerid, is_profile_complete: false)
      expect(s.callout.id).to eq('complete-signup-callout')
      expect(s.callout.primary.path).to eq(routes.educator_profile_form_path)
    end

    %i[rejected_by_sheerid sheerid_expired sheerid_error].each do |fs|
      it "#{fs} before step 4 offers Verify another way" do
        s = status_for(faculty_status: fs, is_profile_complete: false)
        expect(s.state).to eq(:needs_another_way)
        expect(s.badges.map(&:label)).to eq(['Finish signing up'])
        expect(s.callout.primary.label).to eq('Verify another way')
        expect(s.callout.primary.path).to eq(routes.educator_cs_verification_form_path)
      end

      it "#{fs} after step 4 points at support, since the CS form is closed" do
        s = status_for(faculty_status: fs, is_profile_complete: true)
        expect(s.callout.primary.path).to eq(support_path)
      end
    end

    it 'incomplete signup before SheerID starts the verification step' do
      s = status_for(faculty_status: :incomplete_signup, is_profile_complete: false)
      expect(s.state).to eq(:unstarted)
      expect(s.badges.map(&:label)).to eq(['Finish signing up'])
      expect(s.subtitle).to include('Finish signing up to request instructor access')
      expect(s.callout.id).to eq('complete-signup-callout')
      expect(s.callout.primary.path).to eq(routes.educator_sheerid_form_path)
    end

    it 'incomplete signup past SheerID goes to step 4' do
      s = status_for(faculty_status: :incomplete_signup, is_profile_complete: false, is_sheerid_unviable: true)
      expect(s.callout.primary.path).to eq(routes.educator_profile_form_path)
    end

    it 'rejected faculty gets a plain message, the help path and no verified styling' do
      s = status_for(faculty_status: :rejected_faculty, is_profile_complete: true)
      expect(s.state).to eq(:rejected)
      expect(s.badges.map(&:label)).to eq(['Instructor access not active'])
      expect(s.badges.first.tone).to eq(:info)
      expect(s.callout.title).to eq("We couldn't confirm your instructor status")
      expect(s.callout.primary.path).to eq(described_class::REJECTED_HELP_URL)
    end

    it 'finished staff show their role and never see instructor verification wording' do
      s = status_for(role: :librarian, other_role_name: 'Librarian', faculty_status: :incomplete_signup,
                     is_profile_complete: true, self_reported_school: 'Rice University')
      expect(s.state).to eq(:staff)
      expect(s.badges.map(&:label)).to eq(['Librarian'])
      expect(s.subtitle).to include('<strong>Rice University</strong>')
      expect(s.callout).to be_nil
      expect(s.subtitle).not_to match(/instructor/i)
    end

    it 'staff mid signup are sent to the staff details step' do
      s = status_for(role: :librarian, faculty_status: :incomplete_signup, is_profile_complete: false)
      expect(s.state).to eq(:staff_unfinished)
      expect(s.callout.title).to eq('Tell us about your work')
      expect(s.callout.primary.path).to eq(routes.staff_details_form_path)
    end

    it 'shows the school as a second badge when the user has one' do
      user.update!(faculty_status: :confirmed_faculty, school: FactoryBot.create(:school, name: 'Rice University'))
      expect(described_class.new(user).badges.map(&:label)).to eq(['Verified instructor', 'Rice University'])
    end

    it 'never shows the verified badge to anyone unverified' do
      (User::VALID_FACULTY_STATUSES - [User::CONFIRMED_FACULTY]).each do |fs|
        [true, false].each do |complete|
          s = status_for(faculty_status: fs, is_profile_complete: complete)
          expect(s.badges.map(&:tone)).not_to include(:verified), "#{fs} complete=#{complete}"
        end
      end
    end

    it 'never uses em dashes or double hyphens in copy' do
      copy = I18n.t('overview_status').to_s
      expect(copy).not_to include('—')
      expect(copy).not_to include('--')
    end
  end
end
