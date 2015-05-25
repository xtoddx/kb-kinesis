require 'aws-sdk'

class KinesisConsumer
  # FOR THE LOVE OF GOD PLEASE HAVE DATA IN YOUR STREAM ALREADY
  def self.call stream
    shard = first_shard_for_stream(stream)
    response = client.get_shard_iterator(stream_name: stream,
                                         shard_id: shard.shard_id,
                                         shard_iterator_type: 'TRIM_HORIZON'
    iterator = response.data.shard_iterator
    records = []
    while records.empty?
      response = client.get_records shard_iterator: iterator
      records = response.records
      iterator = response.next_shard_iterator
    end
  end

  private

  def self.client
    @_client ||= Aws::Kinesis::Client.new
  end

  def self.first_shard_for_stream name
    stream = find_stream(name)
    stream.shards.first
  end

  def self.find_stream name
    response = client.describe_stream stream_name: name
    response.data.stream_description
  end
end

if $0 == __FILE__
  # SDK knows about env, otherwise do it manually
  Aws.config[:region] = 'us-east-1' unless ENV['AWS_REGION']
  name = ENV['STREAM'] || 'intro-stream'
  KinesisConsumer.call name
end
