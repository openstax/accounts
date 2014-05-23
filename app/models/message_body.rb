class MessageBody < ActiveRecord::Base
  belongs_to :message, inverse_of: :body

  validates_presence_of :message
  #validates_uniqueness_of :message, if: :message_id
  validate :not_empty

  attr_accessible :html, :text, :short_text

  protected

  def not_empty
    return unless [html, text, short_text].all?{|f| f.blank?}
    errors.add(:base, 'cannot be blank')
    false
  end
end
