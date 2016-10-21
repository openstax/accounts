require 'rails_helper'

describe AnonymousUser do
  let!(:au) { AnonymousUser.instance }

  it 'handles faculty status enum methods' do
    expect(au.no_faculty_info?).to be_truthy
    expect(au.pending_faculty?).to be_falsy
    expect(au.rejected_faculty?).to be_falsy
    expect(au.confirmed_faculty?).to be_falsy

    expect(au.faculty_status).to eq "no_faculty_info"
    expect{au.faculty_status="blah"}.not_to raise_error

    expect{au.no_faculty_info!}.not_to raise_error
    expect{au.pending_faculty!}.not_to raise_error
    expect{au.rejected_faculty!}.not_to raise_error
    expect{au.confirmed_faculty!}.not_to raise_error
  end

end
