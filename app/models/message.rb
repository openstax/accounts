class Message < ActiveRecord::Base
  belongs_to :application, class_name: 'Doorkeeper::Application',
                           inverse_of: :messages
  belongs_to :sender, class_name: 'User', inverse_of: :sent_messages

  has_one :body, class_name: 'MessageBody', inverse_of: :message

  has_many :message_contact_infos, inverse_of: :message
  has_many :destinations, through: :message_contact_infos,
                                   source: :contact_info
  has_many :recipients, through: :destinations, source: :user

  before_save :deliver

  #validates :body, presence: true

  #validates :application, presence: true
  #validates :from, presence: true
  #validates :to, presence: true
  #validates :subject, presence: true
  #validates :subject_prefix, presence: true

  attr_accessible :user_id, :to, :cc, :bcc, :subject, :subject_prefix

  def subject_string
    "#{subject_prefix || ''} #{subject}".strip
  end

  def deliver
    SendMessage.call(self)
  end
end
