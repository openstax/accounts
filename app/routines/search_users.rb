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

    users = User.all

    KeywordSearch.search(query) do |with|

      with.default_keyword :any

      with.keyword :username do |usernames|
        sanitized_names = sanitize_strings(usernames, append_wildcard: true,
                                                      prepend_wildcard: options[:admin])

        users = users.where{ username.like_any sanitized_names }
      end

      with.keyword :first_name do |first_names|
        sanitized_names = sanitize_strings(first_names, append_wildcard: true,
                                                        prepend_wildcard: options[:admin])

        users = users.where{ first_name.like_any sanitized_names }
      end

      with.keyword :last_name do |last_names|
        sanitized_names = sanitize_strings(last_names, append_wildcard: true,
                                                       prepend_wildcard: options[:admin])

        users = users.where{ last_name.like_any sanitized_names }
      end

      with.keyword :full_name do |full_names|
        sanitized_names = sanitize_strings(full_names, append_wildcard: true,
                                                       prepend_wildcard: options[:admin])

        users = users.where{ first_name.op('||', ' ').op('||', last_name).like_any sanitized_names }
      end

      with.keyword :name do |names|
        sanitized_names = sanitize_strings(names, append_wildcard: true,
                                                  prepend_wildcard: options[:admin])

        users = users.where do
          first_name.op('||', ' ').op('||', last_name).like_any(sanitized_names) |
                                            first_name.like_any(sanitized_names) |
                                             last_name.like_any(sanitized_names)
        end
      end

      with.keyword :id do |ids|
        users = users.where(id: ids)
      end

      with.keyword :email do |emails|
        sanitized_emails = sanitize_strings(emails, append_wildcard: options[:admin],
                                                    prepend_wildcard: options[:admin])

        users = users.joins(:contact_infos).where{contact_infos.value.like_any sanitized_emails}
        users = users.where(contact_infos: {type: 'EmailAddress',
                                            verified: true,
                                            is_searchable: true}) unless options[:admin]
      end

      # Rerun the queries above for 'any' terms (which are ones without a
      # prefix).

      with.keyword :any do |terms|
        sanitized_terms = sanitize_strings(terms, append_wildcard: options[:admin],
                                                  prepend_wildcard: options[:admin])
        sanitized_names = sanitize_strings(terms, append_wildcard: true,
                                                  prepend_wildcard: options[:admin])

        users = users.joins{contact_infos.outer}.where do
          contact_infos_query = contact_infos.value.like_any sanitized_terms
          contact_infos_query &= (contact_infos.type.eq('EmailAddress') &
                                  contact_infos.verified.eq(true) &
                                  contact_infos.is_searchable.eq(true)) unless options[:admin]

                                              username.like_any(sanitized_names) |
                                            first_name.like_any(sanitized_names) |
                                             last_name.like_any(sanitized_names) |
          first_name.op('||', ' ').op('||', last_name).like_any(sanitized_names) |
                                                                    id.in(terms) |
                                                             contact_infos_query
        end
      end

    end

    # Ordering

    # Parse the input
    order_bys = (options[:order_by] || 'username').split(',').map{ |ob| ob.strip.split(' ') }

    # Toss out bad input, provide default direction
    order_bys = order_bys.map do |order_by|
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
    order_bys = order_bys.map{|order_by| "#{order_by[0]} #{order_by[1]}"}

    order_bys.each do |order_by|
      # postgres requires the "users." bit to make it table_name.column_name
      # otherwise the statement is considered invalid because the order by
      # clause is not in the select clause
      users = users.order("users.#{order_by}")
    end

    # Select only distinct records

    users = users.uniq

    if options[:return_all]
      outputs[:items] = users
      return
    end

    # Count results

    outputs[:total_count] = users.count

    # Return no results if maximum number of results is exceeded

    outputs[:items] = (outputs[:total_count] > MAX_MATCHING_USERS) ? User.none : users

  end

  # Downcase, remove any wildcards and put a wildcard at the end.
  def sanitize_strings(strings, append_wildcard: false, prepend_wildcard: false)
    sanitized_strings = strings.map{ |string| string.downcase.gsub('%', '') }
    sanitized_strings = sanitized_strings.map{ |string| "#{string}%" } if append_wildcard
    sanitized_strings = sanitized_strings.map{ |string| "%#{string}" } if prepend_wildcard
    sanitized_strings
  end

end
