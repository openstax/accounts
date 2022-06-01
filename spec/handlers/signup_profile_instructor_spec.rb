require 'rails_helper'

RSpec.describe SignupProfileInstructor, type: :handler do

  before(:each) do
    load 'db/seeds.rb'
    disable_sfdc_client
  end

  context "when the user has arrived well-formed" do

    let(:user) do
      create_user('user').tap do |uu|
        uu.update_attribute(:state, User::NEEDS_PROFILE)
      end
    end

    context "when required fields are missing" do
      [:first_name, :last_name, :school, :phone_number,
       :url, :num_students, :using_openstax].each do |required_field|
        it "errors if no #{required_field}" do
          outcome = handle(required_field => '')
          expect(outcome.errors).to have_offending_input(required_field)
        end
      end
    end

    it "requires a number >= 0 for num_students" do
      outcome = handle(num_students: "-1")
      expect(outcome.errors).to have_offending_input(:num_students)
    end

    context "when the fields are properly filled in" do
      it "has no errors" do
        outcome = handle
        expect(outcome.errors).to be_empty
      end

      it "updates the user and leaves him 'activated'" do
        handle
        user.reload
        expect(user.first_name).to eq "joe"
        expect(user.last_name).to eq "bob"
        expect(user.self_reported_school).to eq "rice"
        expect(user.state).to eq User::ACTIVATED
      end

      it "agrees to terms for the user" do
        handle
        expect(FinePrint::Signature.where(user_id:  user.id).count).to eq 2
      end
    end

  end

  context "when the user is already activated" do
    let(:user) { create_user('user') }

    it "freaks out" do
      expect{ handle }.to raise_error(Lev::SecurityTransgression)
    end
  end

  def handle(first_name: "joe", last_name: "bob", school: "rice", phone_number: "000-0000",
             subjects: {"accounting"=>"0", "macro_econ"=>"1", "biology"=>"1", "calculus"=>"0"},
             url: "www", num_students: "30", using_openstax: "primary")

    contract_ids = FinePrint::Contract.all.map(&:id)

    described_class.handle(
      params: {
        profile: {
          first_name: first_name,
          last_name: last_name,
          school: school,
          phone_number: phone_number,
          subjects: subjects,
          url: url,
          num_students: num_students,
          using_openstax: using_openstax,
          contract_1_id: contract_ids[0],
          contract_2_id: contract_ids[1]
        }
      },
      caller: user,
      contracts_required: true
    )
  end

end
