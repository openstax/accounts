class UsersController < ApplicationController

  skip_before_filter :registration,
                     only: [:register, :ask_for_email, :edit, :update, :i_clicked_verification_link]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:register, :ask_for_email, :edit, :update, :i_clicked_verification_link]

  def edit
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
    if current_user.update_attributes(user_params)
      redirect_to profile_path, notice: 'Your profile has been updated. These changes may take a few minutes to propagate to the entire site.'
    else
      flash.now[:alert] ||= []
      current_user.errors.full_messages.each do |msg|
        flash.now[:alert] << msg
      end
      render :edit, status: 400
    end
  end

  def register
    if !current_user.is_temp?
      redirect_back
    elsif has_emails_but_none_verified?
      redirect_to verification_sent_path
    elsif request.put?
      handle_with(UsersRegister,
                  contracts_required: !contracts_not_required,
                  success: lambda {
                    redirect_back
                  },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :register, status: errors ? 400 : 200
                  })
    end
  end

  def i_clicked_verification_link
    if has_emails_but_none_verified?
      redirect_to verification_sent_path,
                  alert: "We haven't seen that you clicked the verification link.  Please try again."
    else
      redirect_to :register
    end
  end

  def ask_for_email
    if request.put?
      handle_with(ContactInfosCreate,
                  success: lambda {
                    current_user.registration_redirect_url = stored_url
                    current_user.save
                    redirect_to :verification_sent
                  },
                  failure: lambda {
                    render :ask_for_email, status: 400
                  })
    end
  end

  private

  def user_params
    up = params[:user]
    return {} unless up.is_a? Hash
    up = up.slice(:title, :first_name, :last_name, :suffix)
    up[:full_name] = "#{up[:first_name]} #{up[:last_name]} #{up[:suffix]}"
    up
  end

  def has_emails_but_none_verified?
    current_user.email_addresses.any? && current_user.email_addresses.none?(&:verified)
  end

end
