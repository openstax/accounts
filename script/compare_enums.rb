# Usage: ruby script/compare_enums.rb base.json head.json
# Fails when an enum value that exists on base was changed, removed, or had its integer
# handed to a different name on head. Plain Ruby on purpose: it needs no Rails or bundle.
require 'json'

base_file, head_file = ARGV
abort 'Usage: ruby script/compare_enums.rb base.json head.json' unless base_file && head_file

base = JSON.parse(File.read(base_file))
head = JSON.parse(File.read(head_file))
problems = []

base.each do |enum, base_values|
  head_values = head[enum]
  if head_values.nil?
    problems << "#{enum} exists on base but is missing on head."
    next
  end

  base_values.each do |name, integer|
    if !head_values.key?(name)
      problems << "#{enum}: `#{name}` (#{integer}) was removed."
    elsif head_values[name] != integer
      problems << "#{enum}: `#{name}` changed from #{integer} to #{head_values[name]}."
    end
  end

  base_names_by_integer = base_values.invert
  (head_values.keys - base_values.keys).each do |name|
    holder = base_names_by_integer[head_values[name]]
    next unless holder

    integer = head_values[name]
    problems << "#{enum}: new `#{name}` reuses integer #{integer}, held by `#{holder}` on base."
  end
end

if problems.empty?
  puts 'Enum integers are unchanged from base.'
  exit
end

warn <<~MESSAGE
  Enum integer check failed:

  #{problems.map { |problem| "  - #{problem}" }.join("\n")}

  The database stores each enum's integer, not its name, so existing rows would change meaning.
  Put each old value back on its original integer and give new values an unused one
  (one above the enum's current maximum).
MESSAGE
exit 1
