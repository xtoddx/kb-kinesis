# A simple kinesis + lambda tutorial

## Lesson Zero: Create your environment

Open or create the file `~/.aws/credentials`.
Set the contents like:

    [default]
    aws_access_key_id = ACCESS_KEY
    aws_secret_access_key = SECRET_KEY

Ask an operator if you don't understand how AWS keys work.

You'll probably want to set some restrictive permissions so you don't
leak your security credentials.

    chmod 600 ~/.aws/credentials

As an alternative to a static configuration file you can always put
your key information into the command's environment:

    export AWS_ACCESS_KEY_ID=...
    export AWS_SECRET_ACCESS_KEY=...


## Lesson One: Create a Kinesis Stream

A [Stream][stream] is the storage pipeline that ingests and exposes data.
Any number of devcies, applications, and scripts can push data to the stream.

A stream has 1-or-more Shards, which determine the capacity of the stream.
In this example, we will only use one shard so we have minimal cost.
You can change the number of shards attached to a stream at will.

Take a minute to read and run `01-make-a-stream/main.rb`.
Then think about the following questions.

* What happens when create a stream with a duplicate name?
* What happens if you omit the stream_count option to create_stream?
* Can you create streams with the same names in different regions?

## Lesson Two: Put data into a stream

The data [producer][producer] will send data to the Kinesis Stream.
Per shard you can put up to 1000 requests per second,
with up to 1MB data transfer per second.

You can send a single record at a time, or use a batch-write operation.
Data will stay in the stream up to 24 hours until consumed.
Using the batch write operation you can write up to 5MB per request.

The data you send is an opaque blob to Kinesis,
it will not inspect or otherwise have knowledge of the contents.

Take a minute to read and run `02-produce-data/main.rb`.
Then think about the following questions.

* What criteria should you take into account when selecting a partition key?
* How can you send file contents (< 1 MB)?
* What happens when you exceed your messages / second ratelimit?
* What happens when you exceed your bandwidth / second limit?
* If you are sending a format like JSON that has built-in lists,
  why would you want batch messages instead of one message containing a list?
* You're creating a Kinesis client that uses your credentials.
  Would you want an embedded device to authentiate as you?
* What happens if you pass a stream_name that doesn't exist?

## Lesson Three: Read the stream

The [consumer][consumer] will read data records from the stream.
Per shard you have 2MB per second output.

You read data from a particular shard, not from the overall stream.
Each shard may have many consumers if you are runing a distrubuted workload,
meaning any particular consumer will not see every message,
and some reads will be empty even when there is data in the stream.
(Empty reads still advance the shard iterator.)

You begin by finding the shards through the description of the stream.
You then get a shard iterator that is supplied to the request for records.
Each record response will return zero or more records and a new shard iterator.

You can specify options to getting a shard iterator,
we'll use TRIM_HORIZON as the type to start from the oldest possible point.
Use LATEST for most recent iterator.
If you have a sequence id from publishing a message or from a previous
set of messages,
you can get a shard iterator based on that location in the time stream.
Shard iterators time out after five minutes.

NOTE: The server response is paged in the ruby client,
      but paging seems redundant for Kinesis?

Take a minute to read and run `03-basic-consumer/main.rb`.
Then think about the following questions.

* What happens if you use an invalid shard iterator?
* How will you handle a stream with multiple shards?
* What happens if you don't advacne the shard iterator?
* Can you limit the number of results you recieve per request?
* Is it possible to miss some messages in the stream by using particular
  iterators?
* Can you use iterators to go backwards in a stream and re-read messages?

## Lesson Four: A better reader: KCL

The Kinesis Client Library abstracts away much of the work dealing with
iterators and provides a message-based design.

There is an associated java process that must be launched with your client.
It is shipped with the [KCL java library][kcl-java].

Two files from the aws-kclrb package are included in the work diretory for
this lesson: sample.properties and Rakefile.

To launch the application run `rake run`.
It will download the required java libraries for the MultiLangDaemon and
launch the processing application.

NOTE: in addition to the Kinesis resources that can incur charges,
      the kcl toolkit creates a DynamoDB table.

Take a minute and read and run the source in `04-kcl-consumer` directory.
Then think about the following questsions.

* Do the messages look how you expect?
* How long is the delay between when you publish messages and when they show
  up in the worker?
* What happens if your worker raises an exception when processing a message,
  is that message lost forever?

## Lesson Five: Lambda

[Lambda][lambda] is a nodejs process that runs in response to events in the
AWS ecosystem.
You build "lambda functions" that are zipped javascript resources:
a main script (handler.js) and an optional directory of libraries.

We can use Lambda to build a handler for kinesis events.
We can remove the dependency on any code running under our control
(either manually polling for records or using the MultiLangDaemon)
and trust the entire process to the AWS ecosystem.

A lambda function needs permissions to access our resources.
We will use IAM to build a role that can be assumed by Lambda scripts
and will provide access to kinesis and logging.

Lambda functions that use kinesis poll kinesis for updates.
There are other sources,
like events on s3 buckets,
that directly invoke lambda functions.

Take a minute to read and run `05-lambda-function/main.rb`
and the realted files.
Use the web dashboard to invoke your function a few times.
Use the producer from lesson 02 to send data to the handler,
then check the CloudWatch logs.
Then think about the following questions.

* How does upgrading a kinesis handler differ between KCL and Lambda?
* Can you create a second kinesis stream and have your handler push messages
  to it in response to the messages from the primary stream?


[stream]: http://docs.aws.amazon.com/kinesis/latest/dev/amazon-kinesis-streams.html
[producer]: http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-add-data-to-stream.html
[consumer]: http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-get-data.html
[kcl-java]: https://github.com/awslabs/amazon-kinesis-client
[lambda]: http://aws.amazon.com/lambda/
