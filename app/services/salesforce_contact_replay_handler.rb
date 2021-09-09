class SalesforceContactReplayHandler

  MAX_AGE = 86_400 # 24 hours

  INIT_REPLAY_ID = -1
  DEFAULT_REPLAY_ID = -2

  def initialize()
    @channels = {}
    @push_topic = PushTopic.where(topic_name: SalesforceSubscriber::CONTACT_PUSH_TOPIC_NAME).first
    @replay = SalesforceStreamingReplay.find_or_create_by!(push_topics_id: @push_topic.id)
  end

  # This method is called during the initial subscribe phase
  # in order to send the correct replay ID.
  def [](channel)
    if @replay.replay_id.nil?
      # there is no replay id yet, so just start listening for new events and updating the database with replay ids
      puts "[#{channel}] No timestamp defined, sending magic replay ID #{INIT_REPLAY_ID}"

      INIT_REPLAY_ID
    elsif old_replay_id?
      # the id is too old to playback from the event - so playback all the events from the last 24 hours
      puts "[#{channel}] Old timestamp, sending magic replay ID #{DEFAULT_REPLAY_ID}"
      @replay.destroy!
      @replay = SalesforceStreamingReplay.find_or_create_by!(push_topics_id: @push_topic.id)

      DEFAULT_REPLAY_ID
    else
      @channels[channel] = @replay.replay_id
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
  end
end
