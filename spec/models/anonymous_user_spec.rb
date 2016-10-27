require 'rails_helper'

describe AnonymousUser do
  let!(:au) { AnonymousUser.instance }

  it 'handles faculty status enum methods' do
    expect(au.no_faculty_info?).to be_truthy
    expect(au.pending_faculty?).to be_falsy
    expect(au.rejected_faculty?).to be_falsy
    expect(au.confirmed_faculty?).to be_falsy

    expect(au.faculty_status).to eq "no_faculty_info"
    expect{au.faculty_status="blah"}.to raise_error(AnonymousUserIsImmutableError)

    expect{au.no_faculty_info!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.pending_faculty!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.rejected_faculty!}.to raise_error(AnonymousUserIsImmutableError)
    expect{au.confirmed_faculty!}.to raise_error(AnonymousUserIsImmutableError)
  end

end
