# Routine for searching the Security Log by admins
#
# Caller provides a query and some options.  The query follows the rules of
# https://github.com/bruce/keyword_search , e.g.:
#
#   id:42                --> returns the security log with id 42
#   user:jps,richb       --> returns the security log for requests by the "jps" and "richb" users
#   app:"OpenStax Tutor" --> returns the security log for requests by the OpenStax Tutor application
#   ip:127.0.0.1         --> returns the security log for requests from 127.0.0.1
#   type:admin           --> returns security logs related to admin privileges
#   time:"this week"     --> returns security logs for this week
#   admin                --> returns admin security logs, plus security logs for anyone named admin
#
# Query terms can be combined, e.g.: user:jps app:tutor
# Spaces combine terms with AND; Commas combine terms with OR (same prefix only)
#
# There are currently two options to control query pagination:
#
#   :per_page -- the max number of results to return per page (default: 20)
#   :page     -- the zero-indexed page to return (default: 0)
#
# There is also an option to control the ordering:
#
#   :order_by -- comma-separated list of fields to sort by, with an optional
#                space-separated sort direction (default: "created_at DESC")
#
# The `items` output is an ActiveRecord relation

module Admin
  class SearchSecurityLog

    lev_routine transaction: :no_transaction

    uses_routine OSU::SearchAndOrganizeRelation,
                 as: :search,
                 translations: { outputs: { type: :verbatim } }

    # Downcase and try to convert to an event_type integer
    def self.sanitize_event_types(event_type_strings)
      event_type_strings.map do |event_type_string|
        Integer(event_type_string) \
          rescue SecurityLog.event_types.keys.select{ |key| key.include?(event_type_string) }
                                             .map{ |key| SecurityLog.event_types[key] }
      end.flatten
    end

    # Attempt to transform string representations of times into time ranges
    def self.sanitize_times(time_strings, now)
      time_strings.map do |time_string|
        Chronic.parse(time_string, context: :past, ambiguous_time_range: :none, guess: false) \
          rescue nil
      end.compact
    end

    KEYWORDS = %i[ id user_id user app ip type time any ].freeze

    # Flat list of { keyword:, occurrence:, value: } filter terms, parsed with the same
    # KeywordSearch grammar #exec uses. `occurrence` tells apart separate (AND'd) uses of one
    # keyword; comma-separated (OR'd) values within one occurrence are split out. Negated
    # terms are ignored because #exec's keyword blocks never see them.
    def self.parse_filter_terms(query)
      return [] if query.blank?

      occurrences_by_keyword = Hash.new { |h, k| h[k] = [] }

      KeywordSearch.search(query.to_s) do |with|
        with.default_keyword :any
        KEYWORDS.each do |keyword|
          with.keyword(keyword) { |values| occurrences_by_keyword[keyword].concat(values) }
        end
      end

      occurrences_by_keyword.flat_map do |keyword, occurrences|
        occurrences.each_with_index.flat_map do |raw_value, occurrence|
          raw_value.to_s.split(',').reject(&:blank?).map do |value|
            { keyword: keyword, occurrence: occurrence, value: value }
          end
        end
      end
    rescue KeywordSearch::ParseError
      []
    end

    # The query with one term removed. Values that shared a comma-separated OR group stay joined.
    def self.remove_filter_term(query, keyword:, occurrence:, value:)
      remaining = parse_filter_terms(query).reject do |term|
        term[:keyword].to_s == keyword.to_s &&
          term[:occurrence].to_s == occurrence.to_s &&
          term[:value] == value
      end

      remaining.group_by { |term| [term[:keyword], term[:occurrence]] }.map do |(kw, _), terms|
        joined_value = terms.map { |t| t[:value] }.join(',').delete('"')
        kw == :any ? %("#{joined_value}") : %(#{kw}:"#{joined_value}")
      end.join(' ')
    end

    protected

    SORTABLE_FIELDS = {
      'created_at' => SecurityLog.arel_table[:created_at],
      'user' => User.arel_table[:username],
      'application' => Doorkeeper::Application.arel_table[:name],
      'event_type' => SecurityLog.arel_table[:event_type],
      'id' => SecurityLog.arel_table[:id]
    }

    def exec(params = {}, options = {})

      sec_t = SecurityLog.arel_table
      user_t = User.arel_table
      app_t = Doorkeeper::Application.arel_table

      params[:ob] ||= [{ created_at: :desc }, { id: :desc }]
      relation = SecurityLog.left_joins([:user, :application]).preloaded.reorder(nil)

      run(:search, relation: relation, sortable_fields: SORTABLE_FIELDS, params: params) do |with|

        table = @items.arel_table

        with.default_keyword :any

        with.keyword :id do |ids_array|
          ids_array.each do |ids|
            sanitized_ids = to_number_array(ids)

            @items = @items.where(id: sanitized_ids)
          end
        end

        with.keyword :user_id do |user_ids_array|
          user_ids_array.each do |user_ids|
            sanitized_ids = to_number_array(user_ids)

            @items = @items.where(users: { id: sanitized_ids })
          end
        end

        with.keyword :user do |users_array|
          users_array.each do |users|
            sanitized_names = to_string_array(users, prepend_wildcard: true, append_wildcard: true)
            has_anonymous = sanitized_names.any? do |name|
              'anonymous'.include?(name.downcase.gsub('%', ''))
            end
            has_application = sanitized_names.any? do |name|
              'application'.include?(name.downcase.gsub('%', ''))
            end

            query = user_t[:username].matches_any(sanitized_names).or(
              user_t[:first_name].matches_any(sanitized_names)
            ).or(
              user_t[:last_name].matches_any(sanitized_names)
            )

            if has_anonymous
              query = query.or( user_t[:id].eq(nil).and(app_t[:id].eq(nil)) )
            end

            if has_application
              query = query.or( user_t[:id].eq(nil).and(app_t[:id].not_eq(nil)) )
            end

            @items = @items.where(query)
          end
        end

        with.keyword :app do |apps_array|

          apps_array.each do |apps|
            sanitized_ids = to_number_array(apps)
            sanitized_names = to_string_array(apps, prepend_wildcard: true, append_wildcard: true)
            has_accounts = sanitized_names.any? do |name|
              'openstax accounts'.include?(name.downcase.gsub('%', ''))
            end

            query = app_t[:id].in(sanitized_ids).or(app_t[:name].matches_any(sanitized_names))
            query = query.or( app_t[:id].eq(nil) ) if has_accounts

            @items = @items.where(query)
          end
        end

        with.keyword :ip do |ips_array|
          ips_array.each do |ips|
            sanitized_ips = to_string_array(ips, prepend_wildcard: true, append_wildcard: true)

            @items = @items.where(sec_t[:remote_ip].matches_any(sanitized_ips))
          end
        end

        with.keyword :type do |types_array|
          types_array.each do |types|
            type_strings = to_string_array(types)
            sanitized_event_types = Admin::SearchSecurityLog.sanitize_event_types(type_strings)

            @items = @items.where(event_type: sanitized_event_types)
          end
        end

        with.keyword :time do |times_array|
          times_array.each do |times|
            time_strings = to_string_array(times_array)

            now = Time.now
            beginning_of_hour = now.beginning_of_hour
            midnight = now.midnight
            sanitized_time_ranges = Admin::SearchSecurityLog.sanitize_times(time_strings, now)

            query = nil

            sanitized_time_ranges.each do |sanitized_time_range|
              # This check is a workaround for the fact that context: :past in Chronic
              # ends before the actual current time, depending on the string given
              if sanitized_time_range.last == beginning_of_hour ||
                  sanitized_time_range.last == midnight
                new_query = (sec_t[:created_at].gt(sanitized_time_range.first))
              else
                new_query = (sec_t[:created_at].gt(sanitized_time_range.first))
                  .and(sec_t[:created_at].lt(sanitized_time_range.last))
              end

              query = query.nil? ? new_query : query.or(new_query)
            end

            @items = @items.where(query || '0=1')
          end
        end

        with.keyword :any do |terms_array|
          terms_array.each do |terms|
            sanitized_ids = to_number_array(terms)
            sanitized_names = to_string_array(terms)
            sanitized_names_with_wildcards = sanitized_names.map{ |name| "%#{name}%" }
            sanitized_event_types = Admin::SearchSecurityLog.sanitize_event_types(sanitized_names)
            now = Time.now
            beginning_of_hour = now.beginning_of_hour
            midnight = now.midnight
            sanitized_time_ranges = Admin::SearchSecurityLog.sanitize_times(sanitized_names, now)

            has_anonymous = sanitized_names.any? do |name|
              'anonymous'.include?(name.downcase)
            end
            has_application = sanitized_names.any? do |name|
              'application'.include?(name.downcase)
            end

            has_accounts = sanitized_names.any? do |name|
              'openstax accounts'.include?(name.downcase)
            end

            query = sec_t[:id].in(sanitized_ids).or(
              user_t[:id].in(sanitized_ids)
            ).or(
              app_t[:id].in(sanitized_ids)
            ).or(
              user_t[:first_name].matches_any(sanitized_names_with_wildcards)
            ).or(
              user_t[:last_name].matches_any(sanitized_names_with_wildcards)
            ).or(
              app_t[:name].matches_any(sanitized_names_with_wildcards)
            ).or(
              sec_t[:remote_ip].matches_any(sanitized_names_with_wildcards)
            ).or(
              sec_t[:event_type].in(sanitized_event_types)
            )

            sanitized_time_ranges.each do |sanitized_time_range|
              # This check is a workaround for the fact that context: :past in Chronic
              # ends before the actual current time, depending on the string given
              if sanitized_time_range.last == beginning_of_hour ||
                  sanitized_time_range.last == midnight
                query = query.or(sec_t[:created_at].gt(sanitized_time_range.first))
              else
                query = query.or(
                   (
                     sec_t[:created_at].gt(sanitized_time_range.first)
                   ).and(
                     sec_t[:created_at].lt(sanitized_time_range.last)
                  )
                )
              end
            end

            if has_anonymous
              query = query.or( user_t[:id].eq(nil).and(app_t[:id].eq(nil)) )
            end

            if has_application
              query = query.or( user_t[:id].eq(nil).and(app_t[:id].not_eq(nil)) )
            end

            if has_accounts
              query = query.or( app_t[:id].eq(nil) )
            end

            @items = @items.where(query)
          end
        end

      end

    end

  end
end
