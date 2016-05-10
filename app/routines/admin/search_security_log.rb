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

    protected

    SORTABLE_FIELDS = {
      'created_at' => SecurityLog.arel_table[:created_at],
      'user' => User.arel_table[:username],
      'application' => Doorkeeper::Application.arel_table[:name],
      'event_type' => SecurityLog.arel_table[:event_type]
    }

    def exec(params = {}, options = {})

      params[:ob] ||= { created_at: :desc }
      relation = SecurityLog.preloaded.reorder(nil)

      run(:search, relation: relation, sortable_fields: SORTABLE_FIELDS, params: params) do |with|

        with.default_keyword :any

        with.keyword :id do |ids|
          sanitized_ids = to_number_array(ids)

          @items = @items.where{id.in sanitized_ids}
        end

        with.keyword :user do |users|
          sanitized_ids = to_number_array(users)
          sanitized_names = to_string_array(users, prepend_wildcard: true, append_wildcard: true)
          has_anonymous = sanitized_names.any? do |name|
            'anonymous'.include?(name.downcase.gsub('%', ''))
          end

          if has_anonymous
            @items = @items.joins{user.outer}.where{ (        user.id.eq       nil            ) |
                                                     (        user.id.in       sanitized_ids  ) |
                                                     (  user.username.like_any sanitized_names) |
                                                     (user.first_name.like_any sanitized_names) |
                                                     ( user.last_name.like_any sanitized_names) }
          else
            @items = @items.joins(:user).where{ (        user.id.in       sanitized_ids  ) |
                                                (  user.username.like_any sanitized_names) |
                                                (user.first_name.like_any sanitized_names) |
                                                ( user.last_name.like_any sanitized_names) }
          end
        end

        with.keyword :app do |apps|
          sanitized_ids = to_number_array(apps)
          sanitized_names = to_string_array(apps, prepend_wildcard: true, append_wildcard: true)
          has_accounts = sanitized_names.any? do |name|
            'openstax accounts'.include?(name.downcase.gsub('%', ''))
          end

          if has_accounts
            @items = @items.joins{ application.outer }
                           .where{ (  application.id.eq       nil            ) |
                                   (  application.id.in       sanitized_ids  ) |
                                   (application.name.like_any sanitized_names) }
          else
            @items = @items.joins(:application)
                           .where{ (  application.id.in       sanitized_ids  ) |
                                   (application.name.like_any sanitized_names) }
          end
        end

        with.keyword :ip do |ips|
          sanitized_ips = to_string_array(ips, prepend_wildcard: true, append_wildcard: true)

          @items = @items.where(remote_ip: sanitized_ips)
        end

        with.keyword :type do |types|
          event_type_strings = to_string_array(event_types)
          sanitized_event_types = Admin::SearchSecurityLog.sanitize_event_types(event_type_strings)

          @items = @items.where(event_type: sanitized_event_types)
        end

        with.keyword :any do |terms|
          sanitized_ids = to_number_array(terms)
          sanitized_names = to_string_array(terms, prepend_wildcard: true, append_wildcard: true)
          event_type_strings = to_string_array(terms)
          sanitized_event_types = Admin::SearchSecurityLog.sanitize_event_types(event_type_strings)

          has_anonymous = sanitized_names.any? do |name|
            'anonymous'.include?(name.downcase.gsub('%', ''))
          end

          has_accounts = sanitized_names.any? do |name|
            'openstax accounts'.include?(name.downcase.gsub('%', ''))
          end

          @items = @items.joins{[user.outer, application.outer]}.where{
            query = (              id.in       terms                ) |
                    (         user.id.in       terms                ) |
                    (  application.id.in       terms                ) |
                    (   user.username.like_any sanitized_names      ) |
                    ( user.first_name.like_any sanitized_names      ) |
                    (  user.last_name.like_any sanitized_names      ) |
                    (application.name.like_any sanitized_names      ) |
                    (       remote_ip.like_any sanitized_names      ) |
                    (      event_type.in       sanitized_event_types)
            query = query | (user.id == nil) if has_anonymous
            query = query | (application.id == nil) if has_accounts
            query
          }
        end

      end

    end

  end
end
