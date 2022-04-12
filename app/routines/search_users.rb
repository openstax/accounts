# Routine for searching for users
#
# Caller provides a query and some options.  The query follows the rules of
# https://github.com/bruce/keyword_search , e.g.:
#
#   "name:John" --> returns Users with first or last starting with "John"
#
# Query terms can be combined, e.g. "first_name:michael last_name: harrison"
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

  SORTABLE_FIELDS = %w[first_name last_name id role]
  SORT_ASCENDING = 'ASC'
  SORT_DESCENDING = 'DESC'
  MAX_MATCHING_USERS = 10

  def exec(query, options={})

    users = User.all
    table = User.arel_table
    contact_info_table = ContactInfo.arel_table
    space = Arel::Nodes.build_quoted(' ')
    full_name = Arel::Nodes::NamedFunction.new(
      'concat',
      [
        table[:first_name], space, table[:last_name]
      ]
    )

    KeywordSearch.search(query) do |with|

      with.default_keyword :any

      with.keyword :first_name do |first_names|
        sanitized_names = sanitize_strings(first_names, append_wildcard: true,
                                                        prepend_wildcard: options[:admin])

        users = users.where( table[:first_name].matches_any(sanitized_names) )
      end

      with.keyword :last_name do |last_names|
        sanitized_names = sanitize_strings(last_names, append_wildcard: true,
                                                       prepend_wildcard: options[:admin])

        users = users.where( table[:last_name].matches_any(sanitized_names) )
      end

      with.keyword :full_name do |full_names|
        sanitized_names = sanitize_strings(full_names, append_wildcard: true,
                                                       prepend_wildcard: options[:admin])
        users = users.where( full_name.matches_any(sanitized_names) )
      end

      with.keyword :name do |names|
        sanitized_names = sanitize_strings(names, append_wildcard: true,
                                                  prepend_wildcard: options[:admin])

        users = users.where(
          full_name.matches_any(
            sanitized_names
          ).or(
            table[:first_name].matches_any(sanitized_names)
          ).or(
            table[:last_name].matches_any(sanitized_names)
          )
        )
      end

      with.keyword :uuid do |uuids|
        uuids_queries = uuids.map do |uuid|
          partial_uuid = uuid.to_s.chomp('-')
          next uuid if partial_uuid.include? '-' or partial_uuid.length != 8

          partial_uuid + '-0000-0000-0000-000000000000'..partial_uuid + '-ffff-ffff-ffff-ffffffffffff'
        end
        users = users.where(uuid: uuids_queries)
      end

      with.keyword :id do |ids|
        users = users.where(id: ids)
      end

      with.keyword :email do |emails|
        sanitized_emails = sanitize_strings(emails, append_wildcard: options[:admin], prepend_wildcard: options[:admin])
        users = users.joins(:contact_infos).where( contact_info_table[:value].matches_any(sanitized_emails) )
        users = users.where(contact_infos: {type: 'EmailAddress', verified: true, is_searchable: true}) unless options[:admin]
      end

      # Rerun the queries above for 'any' terms (which are ones without a
      # prefix).

      with.keyword :any do |terms|
        next if terms.blank?

        sanitized_names = sanitize_strings(terms, append_wildcard: true, prepend_wildcard: options[:admin])

        if sanitized_names.length == 2 # looks like a "firstname lastname" search
          users = users.where(
            (
              table[:first_name].matches(sanitized_names.first)
            ).and(
              table[:last_name].matches(sanitized_names.last)
            )
          )
        elsif sanitized_names.any? { |term| term.include?('@') } # we'll assume this means they are searching by an email address
          sanitized_terms = sanitize_strings(terms, append_wildcard: options[:admin], prepend_wildcard: options[:admin])

          contact_infos_query = contact_info_table[:value].matches_any(sanitized_terms)

          unless options[:admin]
            contact_infos_query = contact_infos_query.and(
              contact_info_table[:type].eq('EmailAddress')
            ).and(
              contact_info_table[:verified].eq(true)
            ).and(
              contact_info_table[:is_searchable].eq(true)
            )
          end

          matches_contact_info = ContactInfo.where(contact_infos_query)
          users = User.where(contact_infos: matches_contact_info)

        else # otherwise try to match "all the things"
          matches_first_name = table[:first_name].matches_any(sanitized_names)
          matches_last_name = table[:last_name].matches_any(sanitized_names)
          matches_full_name = full_name.matches_any(sanitized_names)
          matches_id = table[:id].in(terms)

          users = User.where(matches_first_name)
          .or(
            User.where(matches_last_name)
          ).or(
            User.where(matches_full_name)
          ).or(
            User.where(matches_id)
          )
        end
      end
    end

    # Ordering

    # Parse the input
    order_bys = (options[:order_by] || 'last_name').split(',').map{ |ob| ob.strip.split(' ') }

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
    order_bys = [['last_name', SORT_ASCENDING]] if order_bys.empty?

    # Convert to query style
    order_bys = order_bys.map{|order_by| "#{order_by[0]} #{order_by[1]}"}

    order_bys.each do |order_by|
      # postgres requires the "users." bit to make it table_name.column_name
      # otherwise the statement is considered invalid because the order by
      # clause is not in the select clause
      users = users.order("users.#{order_by}")
    end

    users = users.includes(:contact_infos)

    # Select only distinct records
    users = users.distinct

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
