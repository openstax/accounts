module Newflow
  # Thin shim around Salesforce::UpsertLead. Kept so existing callers
  # (EducatorSignup::CompleteProfile, EducatorSignup::SheeridWebhook,
  # Admin::UsersController#force_update_lead) don't have to change.
  # See docs/superpowers/specs/2026-05-20-salesforce-sync-design.md.
  class CreateOrUpdateSalesforceLead
    lev_routine active_job_enqueue_options: { queue: :salesforce }

    protected

    def exec(user:)
      return unless user
      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      Salesforce::UpsertLead.call(user: user)
      outputs.user = user
    end
  end
end
