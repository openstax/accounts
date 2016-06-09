# Routine for searching for users
#
# Caller provides a query and some options.  The query follows the rules of
# https://github.com/bruce/keyword_search , e.g.:
#
#   "username:jps,richb" --> returns the "jps" and "richb" users
#   "name:John" --> returns Users with first or last starting with "John"
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

    @options = options

    users = User.scoped

    KeywordSearch.search(query) do |with|

      with.default_keyword :any

      with.keyword :username do |usernames|
        users = users.where{lower(username).like_any my{prep_names(usernames)}}
      end

      with.keyword :first_name do |first_names|
        users = users.where{lower(first_name).like_any my{prep_names(first_names)}}
      end

      with.keyword :last_name do |last_names|
        users = users.where{lower(last_name).like_any my{prep_names(last_names)}}
      end

      with.keyword :full_name do |names|
        names = prep_names(names)
        users = users.where{ (lower(first_name).op('||', ' ').op('||', lower(last_name)).like_any names) }
      end

      with.keyword :name do |names|
        names = prep_names(names)
        users = users.where{ (lower(first_name).op('||', ' ').op('||', lower(last_name)).like_any names) |
                             (lower(first_name).like_any names) |
                             (lower(last_name).like_any names) }
      end

      with.keyword :id do |ids|
        users = users.where{id.in ids}
      end

      options[:contact_infos_criteria] ||= {type: 'EmailAddress',
                                            verified: true,
                                            is_searchable: true}

      with.keyword :email do |emails|
        emails = options[:prep_emails_proc].call(emails)
        users = users.joins{contact_infos}
                     .where(contact_infos: options[:contact_infos_criteria])
                     .where{lower(contact_infos.value).like_any my{prep_emails(emails)}}
      end

      # Rerun the queries above for 'any' terms (which are ones without a
      # prefix).

      with.keyword :any do |terms|
        names = prep_names(terms)
        emails = prep_emails(terms)

        users = users.joins{contact_infos.outer}.where{
                  (                     username.like_any names)           | \
                  (            lower(first_name).like_any names)           | \
                  (             lower(last_name).like_any names)           | \
                  (lower(first_name)
                     .op('||', ' ')
                     .op('||', lower(last_name)).like_any names)           | \
                  (                           id.in       terms)           | \
                  ((         contact_infos.value.in       emails)          & \
                  (           contact_infos.type.eq       'EmailAddress')  & \
                  (       contact_infos.verified.eq       true)            & \  # TODO use criteria and http://stackoverflow.com/a/14144250
                  (  contact_infos.is_searchable.eq       true))}
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

  # Downcase, remove any wildcards and put a wildcard at the end.
  def prep_names(names)
    names.collect{|name| "#{name.downcase.gsub('%', '')}%"}
  end

  # By default, disallow wildcard search
  def prep_emails(emails)
    @options[:prep_emails_proc] ||= ->(emails) { emails.map{|email| email.gsub('%','')} }
    @options[:prep_emails_proc].call(emails)
  end

end
