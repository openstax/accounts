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

  uses_routine ::SearchUsers,
               as: :search_users,
               translations: { outputs: {type: :verbatim} }

  protected

  def exec(application, query, options={})
    return if application.nil?

    options = options.merge({:return_all => true})
    run(:search_users, query, options)

    per_page = options[:per_page] || 20
    page = options[:page] || 0

    users = outputs[:users].joins(:application_users)
                           .where(:application_users => {
                                    :application_id => application.id})
                           .includes(:application_users)
    num_matching_users = users.count
    users = users.limit(per_page).offset(per_page*page).to_a
    application_users = users.collect{|u| u.application_users}.flatten

    outputs[:num_matching_users] = num_matching_users
    outputs[:per_page] = per_page
    outputs[:page] = page
    outputs[:users] = users
    outputs[:application_users] = application_users
  end

end