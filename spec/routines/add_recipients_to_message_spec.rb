require 'rails_helper'

describe AddRecipientsToMessage do

  let!(:user_1)                { FactoryBot.create :user }

  (2..14).each do |n|
    let!("user_#{n}".to_sym)   { FactoryBot.create :user_with_emails }
  end

  let!(:message) {
    FactoryBot.build(:message, user: user_1)
  }

  it 'adds recipients to message' do
    c = message.message_recipients.length

    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_3))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_4))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_5))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_6))

    AddRecipientsToMessage.call(message, :to,
      literals: [user_3.contact_infos.first.value,
                 user_4.contact_infos.first.value],
      user_ids: [user_5.id, user_6.id])

    expect(message.message_recipients.length).to eq(c + 4)
    expect(message.message_recipients[-4..-1]
      .collect{|mr| mr.recipient_type}).to eq(['to']*4)

    expect(message.message_recipients.collect{|mr| mr.user}).to include(user_3)
    expect(message.message_recipients.collect{|mr| mr.user}).to include(user_4)
    expect(message.message_recipients.collect{|mr| mr.user}).to include(user_5)
    expect(message.message_recipients.collect{|mr| mr.user}).to include(user_6)

    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_7))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_8))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_9))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_10))

    AddRecipientsToMessage.call(message, :cc,
      literals: [user_7.contact_infos.first.value,
                 user_8.contact_infos.first.value],
      user_ids: [user_9.id, user_10.id])

    expect(message.message_recipients.length).to eq(c + 8)
    expect(message.message_recipients[-4..-1]
      .collect{|mr| mr.recipient_type}).to eq(['cc']*4)

    expect(message.message_recipients.collect{|mr| mr.user}).to include(user_7)
    expect(message.message_recipients.collect{|mr| mr.user}).to include(user_8)
    expect(message.message_recipients.collect{|mr| mr.user}).to include(user_9)
    expect(message.message_recipients.collect{|mr| mr.user}).to(
      include(user_10))

    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_11))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_12))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_13))
    expect(message.message_recipients.collect{|mr| mr.user}).not_to(
      include(user_14))

    AddRecipientsToMessage.call(message, :bcc,
      literals: [user_11.contact_infos.first.value,
                 user_12.contact_infos.first.value],
      user_ids: [user_13.id, user_14.id])

    expect(message.message_recipients.length).to eq(c + 12)
    expect(message.message_recipients[-4..-1]
      .collect{|mr| mr.recipient_type}).to eq(['bcc']*4)

    expect(message.message_recipients.collect{|mr| mr.user}).to(
      include(user_11))
    expect(message.message_recipients.collect{|mr| mr.user}).to(
      include(user_12))
    expect(message.message_recipients.collect{|mr| mr.user}).to(
      include(user_13))
    expect(message.message_recipients.collect{|mr| mr.user}).to(
      include(user_14))
  end

end
