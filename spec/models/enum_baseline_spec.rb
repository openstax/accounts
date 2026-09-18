require 'rails_helper'

# Guards the app's positional integer enums against accidental relabeling.
#
# These enums are integer-backed: the database stores the number, never the
# name, so changing a value's integer re-labels every row already written with
# it. This happened for real, back when they were declared as arrays and the
# integer came from array position: four `staff_*` values inserted next to the
# related `educator_*` ones shifted 44 already-deployed values by four.
#
# spec/fixtures/enum_baselines.yml is a checked-in snapshot of every name =>
# integer pair that has ever shipped. This spec asserts that every name in
# the baseline still maps to the same integer today. Appending a brand-new
# name at the end of an enum, with a new higher integer, requires no change
# to the baseline and will not fail here -- that is the safe, normal way to
# grow one of these enums.
describe 'Enum integer stability', type: :model do
  LIVE_ENUM_MAPPINGS = {
    'SecurityLog.event_type' => -> { SecurityLog.event_types },
    'User.role' => -> { User.roles },
    'User.faculty_status' => -> { User.faculty_statuses },
    'User.using_openstax_how' => -> { User.using_openstax_hows },
    'User.school_location' => -> { User.school_locations },
    'User.school_type' => -> { User.school_types },
    'ExternalId.role' => -> { ExternalId.roles },
    'PreAuthState.contact_info_kind' => -> { PreAuthState.contact_info_kinds },
    'SequentialFailure.kind' => -> { SequentialFailure.kinds }
  }.freeze

  def enum_mismatch_message(enum_name, name, expected_integer, actual_integer)
    fate = actual_integer.nil? ? 'no longer exists' : "is now #{actual_integer}"

    <<~MESSAGE

      #{enum_name} value `#{name}` has moved: it used to be integer #{expected_integer}, it #{fate} in the code today.

      This is a POSITIONAL INTEGER ENUM: the database stores the integer, not the name. Every existing row
      that was written as `#{name}` (integer #{expected_integer}) now reads back as whatever name occupies
      integer #{expected_integer} in the current code -- the row's data hasn't changed, but its meaning has.

      This almost always means a new value got inserted in the middle of the enum, the enum got reordered,
      or a value got removed, instead of a new value being appended at the end.

      DO NOT fix this by updating spec/fixtures/enum_baselines.yml -- that file records integers already
      live in production. Instead, edit the enum declaration so `#{name}` reads `#{name}: #{expected_integer}`
      again, and give whatever you just added its own unused integer, one higher than the current maximum.
      Reordering the declaration will not help: each name carries the integer written beside it, so it
      keeps that number wherever it sits in the literal.
    MESSAGE
  end

  def duplicate_integer_message(enum_name, live_mapping)
    duplicates = live_mapping.group_by { |_name, integer|
 integer }.select { |_integer, pairs| pairs.size > 1 }

    lines = duplicates.map do |integer, pairs|
      "  integer #{integer} is shared by: #{pairs.map(&:first).join(', ')}"
    end

    <<~MESSAGE

      #{enum_name} assigns the same integer to more than one name. Rails allows this silently
      (`enum foo: { a: 1, b: 1 }` does not raise), but the database cannot tell those values apart --
      a row stored as one name reads back as whichever name Rails happens to resolve the integer to.

      #{lines.join("\n")}

      Give each name in this enum its own integer.
    MESSAGE
  end

  baseline = YAML.load_file(Rails.root.join('spec/fixtures/enum_baselines.yml'))

  baseline.each do |enum_name, expected_mapping|
    describe enum_name do
      let(:live_mapping) { LIVE_ENUM_MAPPINGS.fetch(enum_name).call }

      expected_mapping.each do |name, expected_integer|
        it "keeps `#{name}` == #{expected_integer}" do
          actual_integer = live_mapping[name]

          expect(actual_integer).to(
            eq(expected_integer),
            enum_mismatch_message(enum_name, name, expected_integer, actual_integer)
          )
        end
      end

      it 'never assigns the same integer to two different names' do
        duplicates = live_mapping.group_by { |_name, integer|
 integer }.select { |_integer, pairs| pairs.size > 1 }

        expect(duplicates).to be_empty, duplicate_integer_message(enum_name, live_mapping)
      end
    end
  end

  it 'keeps ExternalId.role identical to User.role' do
    user_roles = User.roles
    external_id_roles = ExternalId.roles

    expect(external_id_roles).to(
      eq(user_roles),
      "ExternalId.role must map every name to the same integer as User.role (they're compared directly, " \
      "e.g. in ExternalId.find_by_external_id_and_role). Got:\n" \
      "  User.role:       #{user_roles}\n" \
      "  ExternalId.role: #{external_id_roles}"
    )
  end
end
