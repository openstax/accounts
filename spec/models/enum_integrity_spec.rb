require 'rails_helper'

# Checks that need no baseline. The guarantee that no shipped enum value changed
# its integer lives in the Enums workflow (.github/workflows/enums.yml), which
# compares each PR against its base branch.
describe 'Enum integrity', type: :model do
  Rails.application.eager_load!

  # Same discovery as script/dump_enums.rb: key each enum by the class that declares it.
  declared_enums = ApplicationRecord.descendants.flat_map { |model|
    parent = model.superclass
    model.defined_enums.filter_map do |attribute, mapping|
      next if parent.respond_to?(:defined_enums) && parent.defined_enums.key?(attribute)

      ["#{model.name}.#{attribute}", mapping.to_h]
    end
  }

  it 'finds the app enums' do
    expect(declared_enums).not_to be_empty
  end

  declared_enums.each do |enum_name, mapping|
    it "never assigns #{enum_name} the same integer twice" do
      by_integer = mapping.group_by { |_name, integer| integer }
      duplicates = by_integer.select { |_integer, pairs| pairs.size > 1 }
      shared = duplicates.map { |integer, pairs| "#{integer} (#{pairs.map(&:first).join(', ')})" }

      # Rails allows `enum foo: { a: 1, b: 1 }` silently, but the database can't tell them apart.
      expect(duplicates).to be_empty,
                            "#{enum_name} gives one integer to several names: #{shared.join('; ')}"
    end
  end

  it 'keeps ExternalId.role identical to User.role' do
    expect(ExternalId.roles).to(
      eq(User.roles),
      "ExternalId.role must map every name to the same integer as User.role (they're compared " \
      "directly, e.g. in ExternalId.find_by_external_id_and_role). Got:\n" \
      "  User.role:       #{User.roles}\n" \
      "  ExternalId.role: #{ExternalId.roles}"
    )
  end
end
