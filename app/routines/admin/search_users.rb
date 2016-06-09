# Routine for searching for users for admins
#
# Caller provides a query and some options.  The query follows the rules of
# https://github.com/bruce/keyword_search , e.g.:
#
#   "username:jps,richb" --> returns the "jps" and "richb" users
#   "name:John" --> returns Users with first, last, or full name
#                   starting with "John"
#
# Query terms can be combined, e.g. "username:jp first_name:john"
#
# There are currently two options to control query pagination:
#
#   :per_page -- the max number of results to return per page (default: 20)
#   :page     -- the zero-indexed page to return (default: 0)
#
# There is also an option to control the ordering:
#
#   :order_by -- comma-separated list of fields to sort by, with an optional
#                space-separated sort direction (default: "username ASC")
#
# The `users` output is an ActiveRecord relation

module Admin
  class SearchUsers

    lev_routine transaction: :no_transaction

    uses_routine ::SearchUsers,
                 as: :search_users,
                 translations: { outputs: {type: :verbatim} }

    protected

    def exec(query, options={})
      options = options.merge({ return_all: true,
                                contact_infos_criteria: { type: 'EmailAddress' },
                                prep_emails_proc: ->(emails) { emails } })

      run(:search_users, query, options)

      per_page = options[:per_page] || 20
      page = options[:page] || 0

      users = outputs[:items]
      outputs[:total_count] = users.count
      outputs[:items] = users.limit(per_page).offset(per_page*page)
    end

  end
end
