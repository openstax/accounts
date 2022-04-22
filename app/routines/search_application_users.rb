# Routine for searching for ApplicationUsers
#
# Caller provides a query and some options.  The query follows the rules of
# https://github.com/bruce/keyword_search, e.g.:
#
#   "username:jps,richb" --> returns ApplicationUsers for the "jps"
#                            and "richb" Users
#   "name:John" --> returns ApplicationUsers for Users with first, last,
#                   or full name starting with "John"
#
# Query terms can be combined, e.g. "username:jp first_name:john"
#
# There are currently two options to control query pagination:
#
#   :per_page -- the max number of results to return (default: 20)
#   :page     -- the zero-indexed page to return (default: 0)
#
# Unlike the User version, the `users` and `application_users` outputs
# for this routine are arrays, not ActiveRecord relations

class SearchApplicationUsers

  lev_routine transaction: :no_transaction

  uses_routine ::SearchUsers, as: :search_users

  protected

  def exec(application, query, options={})
    return if application.nil?

    options = options.merge(return_all: true)
    users = run(:search_users, query, options).outputs[:items]

    app_id = application.id
    per_page = Integer(options[:per_page]) rescue 20
    page = Integer(options[:page]) rescue 0

    users = users.preload(:application_users).joins(:application_users)
      .where(application_users: { application_id: app_id })
      .limit(per_page).offset(per_page*page)

    outputs[:items] = users
  end

end
