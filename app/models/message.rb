class Message < ActiveRecord::Base
  belongs_to :application, class_name: 'Doorkeeper::Application',
                           inverse_of: :messages
  belongs_to :user, inverse_of: :sent_messages

  has_one :body, class_name: 'MessageBody', inverse_of: :message

  has_many :message_recipients, inverse_of: :message, dependent: :destroy
  has_many :recipients, through: :message_recipients, source: :user
  has_many :recipient_contact_infos, through: :message_recipients,
                                     source: :contact_info

  validates :body, presence: true

  validates :application, presence: true
  validates :message_recipients, presence: true
  validates :subject, presence: true
  validates :subject_prefix, presence: true

  def from_address
    @from_address ||= application.email_from_address
  end

  [:to, :cc, :bcc].each do |dest|
    define_method dest do
      out = {'literals' => [], 'user_ids' => []}
      message_recipients.select{|mr| mr.recipient_type == dest.to_s}
                        .each do |mr|
        if mr.user_id
          out['user_ids'] << mr.user_id
        else
          out['literals'] << mr.value
        end
      end
      out.delete('literals') if out['literals'].blank?
      out.delete('user_ids') if out['user_ids'].blank?
      out.blank? ? nil : out
    end

    define_method "#{dest}_addresses" do
      message_recipients.select{|mr| mr.recipient_type == dest.to_s}
                        .collect{|mr| mr.value}.join(', ')
    end
  end

  def subject_string
    @subject_string ||= "#{subject_prefix || ''} #{subject}".strip
  end
end
