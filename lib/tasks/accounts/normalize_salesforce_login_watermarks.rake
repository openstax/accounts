namespace :accounts do
  desc 'Reset login watermarks left ahead of last_signed_in_at by the Time.current implementation'
  # rake accounts:normalize_salesforce_login_watermarks
  task normalize_salesforce_login_watermarks: :environment do
    # The refresh passes used to stamp Time.current, so a watermark can sit
    # ahead of a login that was never sent; `last_signed_in_at > pushed_at`
    # then excludes it for good. Rows already at or behind last_signed_in_at
    # are correct and left alone.
    #
    # Students get the epoch rather than NULL: pass 1 selects on
    # `salesforce_student_pushed_at IS NULL`, so NULL would queue them for
    # re-linking. The Contact column is pass 3's alone, so NULL is safe there.
    students = ActiveRecord::Base.connection.update(<<~SQL)
      UPDATE users
      SET salesforce_student_pushed_at = '1970-01-01'
      WHERE salesforce_student_pushed_at IS NOT NULL
        AND (last_signed_in_at IS NULL OR salesforce_student_pushed_at > last_signed_in_at)
    SQL

    contacts = ActiveRecord::Base.connection.update(<<~SQL)
      UPDATE users
      SET salesforce_contact_login_pushed_at = NULL
      WHERE salesforce_contact_login_pushed_at IS NOT NULL
        AND (last_signed_in_at IS NULL OR salesforce_contact_login_pushed_at > last_signed_in_at)
    SQL

    puts "Reset #{students} student and #{contacts} Contact login watermark(s)."
  end
end
