class UsersController < ApplicationController

  skip_before_filter :registration, only: [:edit, :update]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:edit, :update]

  def edit
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)

    respond_to do |format|
      if current_user.update_attributes(user_params)
        # debugger
        # format.json { head :ok }
        format.json { render json: {full_name: current_user.guessed_full_name}, status: :ok}
        # format.json { respond_with_bip(current_user) }
        # redirect_to profile_path, notice: 'Your profile has been updated. These changes may take a few minutes to propagate to the entire site.'
      else
        # format.json { respond_with_bip(current_user) }
        # flash.now[:alert] ||= []
        # current_user.errors.full_messages.each do |msg|
        #   flash.now[:alert] << msg
        # end
        # render :edit, status: 400
      end
    end
  end

  private

  def user_params
    up = params[:value].is_a?(Hash) ?
           params[:value] :
           {params[:name] => params[:value]}
    # return {} unless up.is_a? Hash
    # up = up.slice(:title, :first_name, :last_name, :suffix)
    # up[:full_name] = "#{up[:first_name]} #{up[:last_name]} #{up[:suffix]}"
    # up
  end

end
