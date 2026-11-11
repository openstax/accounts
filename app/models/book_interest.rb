# A user's "books you're interested in" list. Salesforce's Subject_Interest__c is
# the source and users.which_books mirrors it, both as one ";"-separated string
# of Salesforce book abbreviations (the `Books` value set). Edits are always
# deltas (add/remove) so values other systems write are never dropped.
module BookInterest

  SEPARATOR = ';'.freeze

  # Accepts a ";"-separated string or an array of such strings.
  def self.parse(value)
    Array(value).flat_map { |item| item.to_s.split(SEPARATOR) }.map(&:strip).reject(&:blank?).uniq
  end

  def self.join(list)
    parse(list).join(SEPARATOR)
  end

  # (current - remove) + add; a book in both lists is removed.
  def self.apply(current, add: [], remove: [])
    removed = parse(remove)
    (parse(current) + parse(add)).uniq - removed
  end

  # Both write only users.which_books; they skip callbacks and validations on purpose.
  def self.set_user!(user, list)
    user.update_column(:which_books, join(list).presence)
  end

  def self.update_user!(user, add: [], remove: [])
    set_user!(user, apply(user.which_books, add: add, remove: remove))
  end

end
