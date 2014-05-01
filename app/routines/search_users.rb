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
# There are currently two options to control query pagination:
#
#   :per_page -- the max number of results to return per page (default: 20)
#   :page     -- the zero-indexed page to return (default: 0)
#
# There is also an option to control the ordering:
#
#   :order_by -- array containing a field names and sort orders
#                (default: ['username', SORT_ASCENDING])
#
# Finally, you can also tell the routine not to count the matching users.
# This will save you a database query if you intend to further modify the
# ActiveRecord::Relation returned
#
#   :no_count -- if true, don't return the matching users count

class SearchUsers

  lev_routine transaction: :no_transaction

protected

  SORTABLE_FIELDS = ['username', 'first_name', 'last_name', 'id']
  SORT_ASCENDING = 'ASC'
  SORT_DESCENDING = 'DESC'

  def exec(query, options={})
    users = User.scoped
    
    KeywordSearch.search(query) do |with|

      with.default_keyword :any

      with.keyword :username do |usernames|
        users = users.where{username.like_any my{prep_usernames(usernames)}}
      end

      with.keyword :first_name do |first_names|
        users = users.where{lower(first_name).like_any my{prep_names(first_names)}}
      end

      with.keyword :last_name do |last_names|
        users = users.where{lower(last_name).like_any my{prep_names(last_names)}}
      end

      with.keyword :full_name do |full_names|
        users = users.where{lower(full_name).like_any my{prep_names(full_names)}}
      end

      with.keyword :name do |names|
        names = prep_names(names)
        users = users.where{ (lower(full_name).like_any names)  | 
                             (lower(last_name).like_any names)  |
                             (lower(first_name).like_any names) }
      end

      with.keyword :id do |ids|
        users = users.where{id.in ids}
      end

      with.keyword :email do |emails|
        users = users.joins{contact_infos}
                     .where{{contact_infos: sift(:email_addresses)}}
                     .where{{contact_infos: sift(:verified)}}
                     .where{contact_infos.value.in emails}
      end

      # Rerun the queries above for 'any' terms (which are ones without a
      # prefix).  

      with.keyword :any do |terms|
        names = prep_names(terms)

        users = users.joins{contact_infos.outer}
                     .where{
                              (         username.like_any  my{prep_usernames(terms)}) |
                              (lower(first_name).like_any  names)                     |
                              (lower(last_name).like_any   names)                     |
                              (lower(full_name).like_any   names)                     |
                              (id.in                       terms)                     |
                              ( (contact_infos.value.in      terms) & 
                                (contact_infos.verified.eq   true) )
                           }
      end

    end

    # Pagination

    page = options[:page] || 0
    per_page = options[:per_page] || 20

    users = users.limit(per_page).offset(per_page*page)

    #
    # Ordering
    #

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

    # Make the ordering call
    order_bys.each do |order_by|
      users = users.order(order_by)
    end

    # Make sure we don't have duplicates (can happen with the joins)

    users = users.uniq

    # Translate to routine outputs

    outputs[:users] = users
    outputs[:query] = query
    outputs[:per_page] = per_page
    outputs[:page] = page
    outputs[:order_by] = order_bys.join(', ') # convert back to one string
    outputs[:num_matching_users] = users.except(:offset, :limit, :order).count \
      unless options[:no_count]
  end

  # Downcase, and put a wildcard at the end.  For the moment don't exclude characters
  def prep_names(names)
    names.collect{|name| name.downcase + '%'}
  end

  def prep_usernames(usernames)
    usernames.collect{|username| username.gsub(User::USERNAME_DISCARDED_CHAR_REGEX,'').downcase + '%'}
  end

end
