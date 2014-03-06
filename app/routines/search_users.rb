
# Routine for searching for users
# 
# Caller provides a query and some options.  The query follows the rules of
# https://github.com/bruce/keyword_search, e.g.:
#
#   "username:jps,richb" --> returns the "jps" and "richb" users
#   "name:John" --> returns Users with first, last, or full name starting with "John"
#
# Query terms can be combined, e.g. "username:jp first_name:john"
#
# There are currently two options to control query pagination:
#
#   :per_page -- the max number of results to return (default: 20)
#   :page     -- the zero-indexed page to return (default: 0)

class SearchUsers

  lev_routine transaction: :no_transaction

protected

  SORTABLE_FIELDS = ['username', 'first_name', 'last_name', 'id']
  SORT_ASCENDING = 'ASC'
  SORT_DESCENDING = 'DESC'

  # TODO increase the security of this search algorithm:
  # 
  #   For certain users we might want to restrict the fields that can be searched 
  #   as well as the fields that are returned.  For example, we probably don't want 
  #   to return email address information to an OpenStax SPA in a client's browser, 
  #   but we'd be ok returning email addresses directly to an OpenStax server.
  #
  #   I favor an approach where no permissions are granted by default -- where the
  #   requesting code has to explicitly say that the search routine can search by
  #   such and such fields and return such and such other fields.  That way it protects
  #   us from accidentally using more fields than we should.
  #
  #   For restriction what fields we return we can use a "select" clause on our query.
  #   This works for fields in User, but what about restricting access to associated
  #   ContactInfos?  Ideally we'd be able to prevent other code from being able to send
  #   this info back to the requestor.  Maybe this logic has to go outside of this class
  #   (like in the API representer or view code).
  #
  #   We should prohibit Users from searching by username or name if they don't provide
  #   enough characters (so as to discourage them from querying all Users or from 
  #   querying all Users whose username starts with 'a', then 'b', then 'c' and so on).
  #   What to do if a first name is "V" or "JP" -- hard to make this restriction here.
  #   Another option might be to limit the number of results for less priviledged 
  #   requestors so they can't query the whole User table.
  #
  #   Maybe we also want to have a default per_page value?  Also, different allowed
  #   max per_page values for different levels of user (e.g. applications can do whatever,
  #   non-admin Users can only get 20 at a time, etc.)

  def exec(query, options={}, type=:any)
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

    # If the query didn't result in any restrictions, either because it was blank
    # or didn't have a keyword from above with appropriate values, then return no
    # results.

    users = User.where('0=1') if User.scoped == users

    # Pagination -- this is where we could modify the incoming values for page
    # and per_page, depending on options

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
    outputs[:per_page] = per_page
    outputs[:page] = page
    outputs[:order_by] = order_bys.join(', ') # convert back to one string
    outputs[:num_matching_users] = users.except(:offset, :limit, :order).count
  end

  # Downcase, and put a wildcard at the end.  For the moment don't exclude characters
  def prep_names(names)
    names.collect{|name| name.downcase + '%'}
  end

  def prep_usernames(usernames)
    usernames.collect{|username| username.gsub(User::USERNAME_DISCARDED_CHAR_REGEX,'').downcase + '%'}
  end

  # Musings on convenience methods for pulling the fields we can search or return
  # out of the options hash passed to `exec`.
  #
  # class Options
  #   def initialize(hash)
  #   end
  #
  #   def can_search?(field)
  #   end
  #
  #   def can_return?(field)
  #   end
  # end

end