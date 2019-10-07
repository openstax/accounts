require 'csv'
require 'faker'

desc "Send PIN confirmation emails, needs EMAILS_CSV_PATH var"
# primarily used for testing the deliverability of the PIN confirmation emails
task :send_pin_confirmation_emails => [:environment] do
  CSV.foreach(ENV['EMAILS_CSV_PATH']) do |row|

    SignupConfirmationMailer.pin_confirmation_email(
        email_address: row[0],
        confirmation_pin: TokenMaker.contact_info_confirmation_pin,
        confirmation_token: TokenMaker.contact_info_confirmation_code,
        user_full_name: Faker::Name.name
    ).deliver_later

  end
  puts 'Done.'
end
