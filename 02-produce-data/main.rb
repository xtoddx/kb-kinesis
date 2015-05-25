require 'aws-sdk'

class KinesisProducer
  def self.call stream, messages
    if messages.length > 1
      client.put_records stream_name: stream,
                         records: messages.map{|x|
                                    {
                                      data: x,
                                      partition_key: partition_key(x)
                                    }
                                  }
    else
      client.put_record stream_name: stream,
                        data: messages.first,
                        partition_key: partition_key(messages.first)

    end
  end

  private

  def self.client
    @_client ||= Aws::Kinesis::Client.new
  end

  def self.partition_key data
    # just a simple incrementer
    # we only have one shard so this doesn't really matter
    @_partition_key ||= 0
    @_partition_key += 1
    @_partition_key.to_s
  end
end

if $0 == __FILE__
  # SDK knows about env, otherwise do it manually
  Aws.config[:region] = 'us-east-1' unless ENV['AWS_REGION']
  name = ENV['STREAM'] || 'intro-stream'
  contents = ARGV.length.nonzero? ? ARGV : ['hello']
  KinesisProducer.call name, contents
end
