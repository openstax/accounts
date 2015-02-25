# Routine for searching for users
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
# By default, the query will return an empty result set if the number of
# results exceeds MAX_MATCHING_USERS
#
# There is an option to control the ordering:
#
#   :order_by -- comma-separated list of fields to sort by, with an optional
#                space-separated sort direction (default: "username ASC")
#
# And an option to control whether wildcard searching is performed:
#   :exact  -- if truthy (not false or nil) the query will only
#              match if the exact terms are present.
#
# You can also tell the routine to return all matching users
#
#   :return_all -- if true, this routine will not limit the query
#                  and will not count the number of results;
#                  all matching users will be returned
#
# The `users` output is an ActiveRecord relation

class SearchUsers

  lev_routine transaction: :no_transaction

  protected

  SORTABLE_FIELDS = ['username', 'first_name', 'last_name', 'id']
  SORT_ASCENDING = 'ASC'
  SORT_DESCENDING = 'DESC'
  MAX_MATCHING_USERS = 10

  def exec(query, options={})

    users = User.scoped

    KeywordSearch.search(query) do |with|

      # a builder for constructing a query clause that runs
      # either a any_like or just an any query
      query_multiple = create_multiple_query_clause(options)

      with.keyword :first_name do |first_names|
         users = users.where{ |q| query_multiple[q, :first_name, first_names] }
      end

      with.default_keyword :any
      with.keyword :username do |usernames|
        users = users.where{ | q | query_multiple[q, :username, usernames] }
      end

      with.keyword :last_name do |last_names|
        users = users.where{ |q| query_multiple[q, :last_name, last_names] }
      end

      with.keyword :full_name do |full_names|
        users = users.where{ |q| query_multiple[q, :full_name, full_names] }
      end

      with.keyword :name do |names|
        names = prep_names(names)
        users = users.where{ |q|
          query_multiple[q, :full_name, names]    |
            query_multiple[q, :first_name, names] |
            query_multiple[q, :last_name, names]
        }
      end

      with.keyword :id do |ids|
        users = users.where{id.in ids}
      end

      with.keyword :email do |emails|
        users = users.joins{contact_infos}
                     .where(contact_infos: {type: 'EmailAddress',
                                            verified: true,
                                            is_searchable: true})
                     .where{contact_infos.value.in emails}
      end

      # Rerun the queries above for 'any' terms (which are ones without a
      # prefix).

      with.keyword :any do |terms|
        names = prep_names(terms,options)

        users = users.joins{contact_infos.outer}.where{
                  (                   username.like_any names)           | \
                  (          lower(first_name).like_any names)           | \
                  (           lower(last_name).like_any names)           | \
                  (           lower(full_name).like_any names)           | \
                  (                         id.in       terms)           | \
                  ((       contact_infos.value.in       terms)           & \
                  (         contact_infos.type.eq       'EmailAddress')  & \
                  (     contact_infos.verified.eq       true)            & \
                  (contact_infos.is_searchable.eq       true))}
      end

    end

    # Select only distinct records
    users = users.uniq

    # Ordering

    # Parse the input
    order_bys = (options[:order_by] || 'username').split(',').collect{|ob| ob.strip.split(' ')}

    # Toss out bad input, provide default direction
    order_bys = order_bys.collect do |order_by|
      field, direction = order_by
      next if !SORTABLE_FIELDS.include?(field)
      direction ||= SORT_ASCENDING
      next if direction != SORT_ASCENDING && direction != SORT_DESCENDING
      [field, direction]
    end

    order_bys.compact!

    # Use a default sort if none provided
    order_bys = ['username', SORT_ASCENDING] if order_bys.empty?

    # Convert to query style
    order_bys = order_bys.collect{|order_by| "#{order_by[0]} #{order_by[1]}"}

    order_bys.each do |order_by|
      # postgres requires the "users." bit to make it table_name.column_name
      # otherwise the statement is considered invalid because the order by
      # clause is not in the select clause
      users = users.order("users.#{order_by}")
    end

    if options[:return_all]
      outputs[:items] = users
      return
    end

    # Count results
    outputs[:total_count] = users.count

    # Return no results if maximum number of results is exceeded
    outputs[:items] = (outputs[:total_count] > MAX_MATCHING_USERS) ?
                        User.none : users

  end

  # Return a lambda that will be used to construct a query that
  # matches a field against multiple values.
  # Wildcard searching via :like_any is performed unless options[:exact] is given
  # called with the sqeel context, the field name, and the array of names to match
  def create_multiple_query_clause(options)
    if options[:exact]
      lambda{ |q,field,names| q.lower(field).eq_any prep_names(names,options) }
    else
      lambda{ |q,field,names| q.lower(field).like_any prep_names(names,options) }
    end
  end

  # Downcase, remove any wildcards and put a wildcard at the end.
  def prep_names(names, options={})
    names.collect{|name| name.delete("%").downcase + ( options[:exact] ? "" : "%" ) }
  end

end
