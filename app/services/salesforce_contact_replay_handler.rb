class SalesforceContactReplayHandler

  MAX_AGE = 86_400 # 24 hours

  INIT_REPLAY_ID = -1
  DEFAULT_REPLAY_ID = -2

  def initialize(topic_id=nil)
    @channels = {}
    push_topic = PushTopic.where(topic_name: SalesforceSubscriber::CONTACT_PUSH_TOPIC_NAME).first
    @replay = SalesforceStreamingReplay.find_or_create_by!(push_topics_id: push_topic.id)
  end

  # This method is called during the initial subscribe phase
  # in order to send the correct replay ID.
  def [](channel)
    if @replay.replay_id.nil?
      puts "[#{channel}] No timestamp defined, sending magic replay ID #{INIT_REPLAY_ID}"

      INIT_REPLAY_ID
    elsif old_replay_id?
      puts "[#{channel}] Old timestamp, sending magic replay ID #{DEFAULT_REPLAY_ID}"

      DEFAULT_REPLAY_ID
    else
      @channels[channel]
    end
  end

  def []=(channel, replay_id)
    puts "[#{channel}] Writing replay ID: #{replay_id}"

    @replay.replay_id = replay_id
    @replay.save!
    @channels[channel] = replay_id
  end

  def old_replay_id?
    @replay.updated_at.is_a?(Time) && Time.now - @replay.updated_at > MAX_AGE
    @replay.destroy!
  end
end
