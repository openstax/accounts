class Message < OpenStruct
  # This will become an ActiveRecord model once we start saving messages

  def subject_string
    "#{subject_prefix || ''} #{subject}".strip
  end

  def deliver
    msg = self
    Mail.deliver do
      from msg.from
      to msg.to
      cc msg.cc
      bcc msg.bcc
      subject msg.subject_string

      html_part do
        content_type 'text/html; charset=UTF-8'
        body msg.body.html
      end

      text_part do
        body msg.body.text
      end
    end
  end
end
