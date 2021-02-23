class RemoveDuplicateEmails
  def run(do_it: false, older_than: '2020-10-01' )
    # find all duplicate contact infos, older than X
    all_dup_contact_infos = ContactInfo.
      where("created_at < ?", Date.strptime(older_than, "%Y-%m-%d")).
      select(:type, :value).group(:type, :value).
      having('count(*) > 1')
    users_to_remove = [], contactinfos_to_remove = []

    all_dup_contact_infos.each do |dup_contact_info|
      # of the duplicate contact infos value ... find the unverified duplicates
      unverified_contactinfos = ContactInfo.where(type: dup_contact_info.type, value: dup_contact_info.value, verified: false)

      unverified_contactinfos.each do |unverified_contactinfo|
        if unverified_contactinfo.user.contact_infos.count == 1 && unverified_contactinfo.user.contact_infos.first.value == unverified_contactinfo.value
          # this is a dup user with just this one unverified email
          users_to_remove.append(unverified_contactinfo.user.id)
        else
          # this is a dup contact info that's unverified w/ no 1:1 user
          contactinfos_to_remove.append(unverified_contactinfo.id)
        end
      end
    end

    users_to_remove = users_to_remove.flatten.uniq.sort
    contactinfos_to_remove = contactinfos_to_remove.flatten.uniq.sort

    if do_it
      ActiveRecord::Base.transaction do
        ContactInfo.where(id: contactinfos_to_remove).destroy_all
        User.where(id: users_to_remove).destroy_all
      end
    end

    puts "Remove Duplicate emails script finished."
    puts "\t#{users_to_remove.count} Users removed: #{users_to_remove.inspect}"
    puts "\t#{contactinfos_to_remove.count} ContactInfos removed: #{contactinfos_to_remove.inspect}"
  end
end
