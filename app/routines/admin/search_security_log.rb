# Routine for searching the Security Log by admins
#
# Caller provides a query and some options.  The query follows the rules of
# https://github.com/bruce/keyword_search , e.g.:
#
#   "user:jps,richb" --> returns the security log for the "jps" and "richb" users
#   "application:Tutor" --> returns the security log for the Tutor application
#
# Query terms can be combined, e.g. "user:jp application:tutor"
#
# There are currently two options to control query pagination:
#
#   :per_page -- the max number of results to return per page (default: 20)
#   :page     -- the zero-indexed page to return (default: 0)
#
# There is also an option to control the ordering:
#
#   :order_by -- comma-separated list of fields to sort by, with an optional
#                space-separated sort direction (default: "username ASC")
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
        Integer(event_type) \
          rescue SecurityLog.event_types.keys.select{ |key| key.include?(event_type_string) }
                                             .map{ |key| SecurityLog.event_types[key] }
      end
    end

    # Attempt to transform string representations of times into time ranges
    def self.sanitize_times(time_strings, now)
      time_strings.map do |time_string|
        Chronic.parse(time_string, context: :past, ambiguous_time_range: :none, guess: false) \
          rescue nil
      end.compact
    end

    protected

    SORTABLE_FIELDS = {
      'created_at' => SecurityLog.arel_table[:created_at],
      'user' => User.arel_table[:username],
      'application' => Doorkeeper::Application.arel_table[:name],
      'event_type' => SecurityLog.arel_table[:event_type]
    }

    def exec(params = {}, options = {})

      params[:ob] ||= { created_at: :desc }
      relation = SecurityLog.joins{[user.outer, application.outer]}.preloaded.reorder(nil)

      run(:search, relation: relation, sortable_fields: SORTABLE_FIELDS, params: params) do |with|

        with.default_keyword :any

        with.keyword :id do |ids_array|
          ids_array.each do |ids|
            sanitized_ids = to_number_array(ids)

            @items = @items.where { id.in sanitized_ids }
          end
        end

        with.keyword :user do |users_array|
          users_array.each do |users|
            sanitized_ids = to_number_array(users)
            sanitized_names = to_string_array(users, prepend_wildcard: true, append_wildcard: true)
            has_anonymous = sanitized_names.any? do |name|
              'anonymous'.include?(name.downcase.gsub('%', ''))
            end
            has_application = sanitized_names.any? do |name|
              'application'.include?(name.downcase.gsub('%', ''))
            end

            @items = @items.where do
              query = (        user.id.in       sanitized_ids  ) |
                      (  user.username.like_any sanitized_names) |
                      (user.first_name.like_any sanitized_names) |
                      ( user.last_name.like_any sanitized_names)
              query = query | ((user.id.eq nil) & (application.id.eq     nil)) if has_anonymous
              query = query | ((user.id.eq nil) & (application.id.not_eq nil)) if has_application
              query
            end
          end
        end

        with.keyword :app do |apps_array|
          apps_array.each do |apps|
            sanitized_ids = to_number_array(apps)
            sanitized_names = to_string_array(apps, prepend_wildcard: true, append_wildcard: true)
            has_accounts = sanitized_names.any? do |name|
              'openstax accounts'.include?(name.downcase.gsub('%', ''))
            end

            @items = @items.where do
              query = (  application.id.in       sanitized_ids  ) |
                      (application.name.like_any sanitized_names)
              query = query | (application.id.eq nil) if has_accounts
              query
            end
          end
        end

        with.keyword :ip do |ips_array|
          ips_array.each do |ips|
            sanitized_ips = to_string_array(ips, prepend_wildcard: true, append_wildcard: true)

            @items = @items.where { remote_ip.like_any sanitized_ips }
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
            time_strings = to_string_array(times)
            now = Time.now
            beginning_of_hour = now.beginning_of_hour
            midnight = now.midnight
            sanitized_time_ranges = Admin::SearchSecurityLog.sanitize_times(time_strings, now)

            @items = @items.where do
              query = nil

              sanitized_time_ranges.each do |sanitized_time_range|
                # This check is a workaround for the fact that context: :past in Chronic
                # ends before the actual current time, depending on the string given
                if sanitized_time_range.last == beginning_of_hour ||
                   sanitized_time_range.last == midnight
                  new_query = (created_at > sanitized_time_range.first)
                else
                  new_query = ((created_at > sanitized_time_range.first) &
                               (created_at < sanitized_time_range.last))
                end

                query = query.nil? ? new_query : query | new_query
              end

              query || `0=1`
            end
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

            @items = @items.where do
              query = (              id.in       sanitized_ids                 ) |
                      (         user.id.in       sanitized_ids                 ) |
                      (  application.id.in       sanitized_ids                 ) |
                      (   user.username.like_any sanitized_names_with_wildcards) |
                      ( user.first_name.like_any sanitized_names_with_wildcards) |
                      (  user.last_name.like_any sanitized_names_with_wildcards) |
                      (application.name.like_any sanitized_names_with_wildcards) |
                      (       remote_ip.like_any sanitized_names_with_wildcards) |
                      (      event_type.in       sanitized_event_types)
              sanitized_time_ranges.each do |sanitized_time_range|
                # This check is a workaround for the fact that context: :past in Chronic
                # ends before the actual current time, depending on the string given
                if sanitized_time_range.last == beginning_of_hour ||
                   sanitized_time_range.last == midnight
                  query = query | (created_at > sanitized_time_range.first)
                else
                  query = query | ((created_at > sanitized_time_range.first) &
                                   (created_at < sanitized_time_range.last))
                end
              end
              query = query | ((user.id.eq nil) & (application.id.eq     nil)) if has_anonymous
              query = query | ((user.id.eq nil) & (application.id.not_eq nil)) if has_application
              query = query | (application.id.eq nil)                          if has_accounts
              query
            end
          end
        end

      end

    end

  end
end
