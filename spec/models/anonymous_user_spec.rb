require 'rails_helper'

describe AnonymousUser do
  let!(:au) { AnonymousUser.instance }

  it 'handles faculty status enum methods' do
    expect(au.incomplete_signup?).to be_truthy
    expect(au.no_faculty_info?).to be_falsy
    expect(au.pending_faculty?).to be_falsy
    expect(au.rejected_faculty?).to be_falsy
    expect(au.pending_sheerid?).to be_falsy
    expect(au.rejected_by_sheerid?).to be_falsy
    expect(au.confirmed_faculty?).to be_falsy

    expect(au.faculty_status).to eq "incomplete_signup"
    expect{au.faculty_status="blah"}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.no_faculty_info!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.pending_faculty!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.rejected_faculty!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.confirmed_faculty!}.to raise_error(AnonymousUserIsImmutableError)

    expect(au.school_type).to eq "unknown_school_type"
    expect{au.school_type="blah"}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.unknown_school_type!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.other_school_type!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.college!}.to raise_error(AnonymousUserIsImmutableError)
  end

end
