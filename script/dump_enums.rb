# Prints every ActiveRecord enum as sorted JSON: { "Class.enum" => { name => integer } }.
# Run with `bin/rails runner script/dump_enums.rb`; the Enums workflow runs it on both
# the PR head and its base, so keep it free of dependencies on anything else in the repo.
Rails.application.eager_load!

enums = {}
ApplicationRecord.descendants.each do |model|
  model.defined_enums.each do |attribute, mapping|
    # STI subclasses inherit their parent's enums; key each one by the class that declares it.
    parent = model.superclass
    next if parent.respond_to?(:defined_enums) && parent.defined_enums.key?(attribute)

    by_integer = mapping.to_h.sort_by { |name, integer| [integer, name] }
    enums["#{model.name}.#{attribute}"] = by_integer.to_h
  end
end

puts JSON.pretty_generate(enums.sort.to_h)
