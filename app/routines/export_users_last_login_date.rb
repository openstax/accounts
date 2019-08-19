class ExportUsersLastLoginDate
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
        emails: user.contact_infos.verified.map(&:value).join(", "),
        last_login_at: SecurityLog.sign_in_successful
                                    .where(user_id: user.id)
                                    .first&.created_at&.strftime("%m/%d/%Y %I:%M%p %Z")
      })
    end
    output_users
  end

  def generate_csv
    CSV.open(filename, 'w') do |file|
      file.add_row ([
          "Email(s)",
          "Last login date",
      ])

      info.each do |hashie|
        file.add_row([
          hashie.emails,
          hashie.last_login_at,
        ])
      end
    end
  end

  def filename
    File.join exports_folder, "users_last_login_date.csv"
  end

  def exports_folder
    'tmp'
  end

  def remove_exported_files
    File.delete(filename) if File.exist?(filename)
  end
end
