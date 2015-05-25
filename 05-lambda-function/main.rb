require 'aws-sdk'

class LambdaFunctionPublisher
  def self.call name
    # arn = create_iam_role
    # sleep 10 # because I don't know why - IAM::Client#wait_for events = []
    arn = 'arn:aws:iam::957454679275:role/kinesis-lambda-role'
    publish_lambda_function name, arn
    add_stream_source name, ENV['STREAM'] || 'intro-stream'
  end

  private

  def self.create_iam_role
    response = iam_client.create_role role_name: 'kinesis-lambda-role',
                                      assume_role_policy_document:  trust_policy
    arn = response.data.role.arn
    iam_client.put_role_policy role_name: 'kinesis-lambda-role',
                               policy_name: 'allow-kinesis-access',
                               policy_document: permission_policy
    arn
  end

  def self.publish_lambda_function name, arn
    client.create_function function_name: name,
                           runtime: 'nodejs',
                           role: arn,
                           handler: 'handler.handler',
                           code: {zip_file: zip_function}
  end

  def self.add_stream_source function_name, stream_name
    arn = stream_arn(stream_name)
    client.create_event_source_mapping event_source_arn: arn,
                                       function_name: function_name,
                                       starting_position: 'TRIM_HORIZON'
  end

  def self.zip_function
    Dir.chdir(File.expand_path('..', __FILE__)) do
      system('zip --quiet code.zip handler.js')
    end
    File.read(File.expand_path('../code.zip', __FILE__))
  end

  def self.trust_policy
    File.read(File.expand_path('../trust_policy.json', __FILE__))
  end

  def self.permission_policy
    File.read(File.expand_path('../permission_policy.json', __FILE__))
  end

  def self.stream_arn name
    response = kinesis_client.describe_stream(stream_name: name)
    response.data.stream_description.stream_arn
  end

  def self.iam_client
    Aws::IAM::Client.new
  end

  def self.kinesis_client
    Aws::Kinesis::Client.new
  end

  def self.client
    Aws::Lambda::Client.new
  end
end

if $0 == __FILE__
  # SDK knows about env, otherwise do it manually
  Aws.config[:region] = 'us-east-1' unless ENV['AWS_REGION']
  LambdaFunctionPublisher.call 'kinesis-lambda-intro'
end
