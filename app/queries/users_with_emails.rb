
class UsersWithEmails

  def self.all(emails)
    User.joins{contact_infos}
        .where{contact_infos.type == 'EmailAddress'}
        .where{contact_infos.value.in emails}.all
  end

end