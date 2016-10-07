class ExportUsersInfoToMatchWithConsentForms
  lev_routine

  protected

  def exec(delete_after: true)
    outputs[:filename] = filename
    outputs[:info] = info
    generate_csv
    remove_exported_files if delete_after
  end

  def info
    output_users = []
    User.preload(:contact_infos).find_each do |user|
      output_users << Hashie::Mash.new({
        user_id: user.id,
        name: user.name,
        username: user.username,
        emails: user.contact_infos.map(&:value).join(", ")
      })
    end
    output_users
  end

  def generate_csv
    CSV.open(filename, 'w') do |file|
      file.add_row ([
        "User ID",
        "Name",
        "Username",
        "Email(s)"
      ])

      info.each do |hashie|
        file.add_row([
          hashie.user_id,
          hashie.name,
          hashie.username,
          hashie.emails
        ])
      end
    end
  end

  def filename
    File.join exports_folder, "users_email_info_to_match_with_consent_forms.csv"
  end

  def exports_folder
    File.join 'tmp'
  end

  def remove_exported_files
    File.delete(filename) if File.exist?(filename)
  end
end
