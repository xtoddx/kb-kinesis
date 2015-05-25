require 'aws-sdk'

class ShardCreator
  def self.call name, shard_count
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/Kinesis/Client.html
    #     #create_stream-instance_method
    client.create_stream stream_name: name, shard_count: shard_count
  end

  private

  def self.client
    @_client ||= Aws::Kinesis::Client.new
  end
end

if $0 == __FILE__
  # SDK knows about env, otherwise do it manually
  Aws.config[:region] = 'us-east-1' unless ENV['AWS_REGION']
  name = ARGV.shift || 'intro-stream'
  ShardCreator.call name, shards=1
end
