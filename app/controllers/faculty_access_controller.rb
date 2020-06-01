class FacultyAccessController < ApplicationController

  prepend_before_action :disallow_signup, only: :apply
  before_action :redirect_to_sheerid_if_newflow, only: [:apply]

  helper_method :instructor_has_selected_subject

  def apply
    if request.post?
      handler = case params[:apply][:role]
      when "instructor"
        FacultyAccessApplyInstructor
      else
        FacultyAccessApplyOther
      end

      handle_with(handler,
                  success: lambda do
                    new_email = @handler_result.outputs.new_email
                    if new_email.present?
                      security_log :contact_info_created,
                                   contact_info_id: new_email.id,
                                   contact_info_type: new_email.type,
                                   contact_info_value: new_email.value
                    end
                    redirect_to action: :pending
                  end,
                  failure: lambda do
                    render :apply
                  end)
    end
  end

  def pending
    redirect_back if request.post?
  end

  protected

  def redirect_to_sheerid_if_newflow
    if Settings::Db.store.educator_feature_flag
      redirect_to(educator_sheerid_form_path)
    end
  end

  def instructor_has_selected_subject(key)
    params[:apply] && params[:apply][:subjects] && params[:apply][:subjects][key] == '1'
  end

  def disallow_signup
    # value doesn't really matter, if set at all, signup hidden
    params[:no_signup] = 1
  end

end
