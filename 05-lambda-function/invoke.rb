require 'aws-sdk'
require 'awesome_print'

class LambdaFunctionInvoker
  def self.call name, payload
    response = client.invoke function_name: name,
                             invocation_type: 'Event',
                             payload: payload
    ap response.data.payload.read
  end

  private

  def self.client
    Aws::Lambda::Client.new
  end
end

if $0 == __FILE__
  # SDK knows about env, otherwise do it manually
  Aws.config[:region] = 'us-east-1' unless ENV['AWS_REGION']
  body = File.read(File.expand_path('../payload.json', __FILE__))
  LambdaFunctionInvoker.call 'kinesis-lambda-intro', body
end
