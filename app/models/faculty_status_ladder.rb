# The one place that decides whether an automated writer may change a user's
# faculty_status. Signup progresses up the ladder; nothing automated may move a
# user down it, because every "down" we have seen in practice was a stale record
# (the SheerID webhook's own lead push, a Lead that a failed step-4 save left
# behind) overwriting a real outcome.
#
# Deliberate writers -- SwitchSignupRole, the admin user form -- bypass this and
# assign the column directly.
module FacultyStatusLadder
  RANK = {
    'no_faculty_info'     => 0,
    'incomplete_signup'   => 1,
    'pending_sheerid'     => 2,
    'sheerid_expired'     => 2,
    'sheerid_error'       => 2,
    'rejected_by_sheerid' => 2,
    'pending_faculty'     => 3,
    'confirmed_faculty'   => 4,
    'rejected_faculty'    => 4
  }.freeze

  TERMINAL_RANK = 4
  SHEERID_RANK = 2

  SOURCES = %i[accounts salesforce].freeze

  # source: :accounts for the webhook, lead pushes and nightly jobs;
  #         :salesforce for values read back from a Lead or Contact (CX decisions).
  # Same-rank moves are allowed among the SheerID states (a verification evolves)
  # and, only from Salesforce, between the terminal states (CX may flip a
  # confirmed instructor to rejected or back).
  def self.allowed?(from:, to:, source:)
    raise ArgumentError, "unknown source #{source.inspect}" unless SOURCES.include?(source)

    from_rank = RANK[from.to_s]
    to_rank = RANK[to.to_s]
    return false if to_rank.nil?
    return true if from.to_s == to.to_s
    return true if from_rank.nil? || to_rank > from_rank
    return false if to_rank < from_rank

    case to_rank
    when SHEERID_RANK then true
    when TERMINAL_RANK then source == :salesforce
    else false
    end
  end
end
