class DataExport

  lev_routine

  protected

  def exec(user)
    fatal_error(code: :no_user) if user.nil?

    outputs.data = {
      profile: profile(user),
      contact_infos: user.contact_infos.order(:created_at).map { |ci| contact_info(ci) },
      authentications: user.authentications.order(:created_at).map { |a| authentication(a) },
      external_ids: user.external_ids.order(:created_at).map { |e| external_id(e) },
      external_uuids: user.external_uuids.order(:created_at).map { |u| { uuid: u.uuid, created_at: u.created_at } },
      school: user.school&.then { |s| { name: s.name } },
      exported_at: Time.now.utc.iso8601
    }
  end

  private

  def profile(user)
    {
      uuid: user.uuid,
      username: user.username,
      first_name: user.first_name,
      last_name: user.last_name,
      title: user.title,
      suffix: user.suffix,
      role: user.role,
      self_reported_school: user.self_reported_school,
      phone_number: user.phone_number,
      country_code: user.country_code,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def contact_info(contact)
    {
      type: contact.type,
      value: contact.value,
      verified: contact.verified,
      is_searchable: contact.is_searchable,
      created_at: contact.created_at
    }
  end

  def authentication(auth)
    # Provider name and timestamp only - never the uid/token, which is a credential
    {
      provider: auth.provider,
      created_at: auth.created_at
    }
  end

  def external_id(external)
    {
      external_id: external.external_id,
      role: external.role,
      created_at: external.created_at
    }
  end
end
