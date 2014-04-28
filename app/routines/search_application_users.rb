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

class SearchApplicationUsers
  
  lev_routine transaction: :no_transaction

  uses_routine SearchUsers,
               as: :search_users,
               translations: { outputs: {type: :verbatim} }

  protected
  
  SORTABLE_FIELDS = ['username', 'first_name', 'last_name', 'id']
  SORT_ASCENDING = 'ASC'
  SORT_DESCENDING = 'DESC'

  def exec(application, query, options={})
    return if application.nil?

    options = options.merge({:no_count => true})
    run(:search_users, query, options)

    page = outputs[:page]
    per_page = outputs[:per_page]
    outputs[:users] = outputs[:users].joins(:application_users)
                                     .where(:application_users => {:application_id => application.id})
    users = outputs[:users].limit(nil).offset(nil)
    app_users = ApplicationUser.where{id.in users.select(:application_users => :id)}

    outputs[:num_matching_users] = users.count
    outputs[:application_users] = app_users.limit(per_page).offset(per_page*page)
  end

end