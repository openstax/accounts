namespace :accounts do
  desc 'One-time repush: push a Lead for any user whose faculty_status has moved past ' \
       'incomplete_signup on a stale Lead'
  # rake accounts:repush_incomplete_signup_leads
  # DRY_RUN=true rake accounts:repush_incomplete_signup_leads
  task repush_incomplete_signup_leads: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    batch_size = 2000
    incomplete_rank = FacultyStatusLadder::RANK.fetch(User::INCOMPLETE_SIGNUP)
    counts = { pushed: 0, skipped: 0, failed: 0 }
    after_id = nil

    fetch_leads = lambda do |cursor|
      query = OpenStax::Salesforce::Remote::Lead
              .select(:id, :accounts_uuid)
              .where(verification_status: User::INCOMPLETE_SIGNUP)
              .where('Accounts_UUID__c != null')
              .where(is_converted: false)
      query = query.where('Id > ?', cursor) if cursor.present?
      query.order('Id').limit(batch_size).to_a
    end

    loop do
      leads = fetch_leads.call(after_id)
      break if leads.empty?

      users_by_uuid = User.where(uuid: leads.map(&:accounts_uuid)).index_by(&:uuid)

      leads.each do |lead|
        user = users_by_uuid[lead.accounts_uuid]
        unless user && FacultyStatusLadder::RANK.fetch(user.faculty_status, 0) > incomplete_rank
          counts[:skipped] += 1
          next
        end

        if dry_run
          counts[:pushed] += 1
          next
        end

        begin
          result = Newflow::CreateOrUpdateSalesforceLead.call(user: user)
          if result.outputs.lead_saved || result.outputs.contact_saved
            counts[:pushed] += 1
          else
            counts[:failed] += 1
          end
        rescue StandardError => e
          counts[:failed] += 1
          Sentry.capture_exception(e, extra: { user_id: user.id, salesforce_lead_id: lead.id })
        end
      end

      break if leads.length < batch_size

      after_id = leads.last.id
    end

    STDOUT.puts(dry_run ? 'DRY RUN -- no leads pushed.' : 'Done.')
    STDOUT.puts(
      "pushed: #{counts[:pushed]}, skipped: #{counts[:skipped]}, failed: #{counts[:failed]}"
    )
  end
end
