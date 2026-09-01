module Legacy
  class UsersController < ApplicationController
    include LegacyHelper

    # Attributes the profile page's single-field editors are allowed to write.
    # That branch names its attribute from the request (x-editable sends the
    # element's `data-name`) and builds a plain Hash, which does not go through
    # strong parameters -- so the set has to be closed here rather than at
    # assignment.
    SINGLE_EDITABLE_FIELDS = %w[username title first_name last_name suffix].freeze

    before_action :redirect_to_newflow_if_enabled, only: [:edit]

    fine_print_skip :general_terms_of_use, :privacy_policy, only: [:update]

    before_action :allow_iframe_access, only: [:edit, :update]
    before_action :prevent_caching, only: [:edit, :update]

    def edit
      OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
    end

    def update
      OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)

      # Rendered outside a `respond_to`: the only caller is the profile page's
      # inline editors, there is no HTML representation of this action, and a
      # format that a `format.json`-only block doesn't list raises UnknownFormat
      # -- which comes back as a full HTML error page that x-editable then
      # injects into the form as markup.
      if current_user.update(user_params)
        security_log :user_updated, user_params: user_params

        render json: { full_name: current_user.full_name }, status: :ok
      else
        render json: { errors: current_user.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    private

    def user_params
      unless params[:value].is_a?(String)
        return params.require(:value).permit(:title, :first_name, :last_name, :suffix).to_h
      end

      raise(Lev::SecurityTransgression) unless SINGLE_EDITABLE_FIELDS.include?(params[:name])

      { params[:name] => params[:value] }
    end
  end
end
