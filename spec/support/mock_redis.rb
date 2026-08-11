require 'mock_redis'

# Route all Redis clients created during an example to a fresh in-memory fake.
# Jobba memoizes its client, so reset it each example to pick up the new fake.
RSpec.configure do |config|
  config.before(:each) do
    mock = MockRedis.new
    allow(Redis).to receive(:new).and_return(mock)
    Jobba.instance_variable_set(:@redis, nil)
  end
end
