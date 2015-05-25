#!/usr/bin/env ruby

require 'bundler/setup'

require 'aws/kclrb'

# The MultiLangDaemon uses STDOUT, so we'll write to a log.
require 'logger'

class AdvancedConsumer < Aws::KCLrb::RecordProcessorBase
  def init_processor shard_id
    logger.info "processor init #{shard_id.inspect}"
  end

  def process_records records, checkpointer
    logger.info "process records: #{records.inspect}"
    logger.info "data: #{records.map{|x| x['data']}.inspect}"
    logger.info "checkpointer: #{checkpointer.inspect}"
  end

  def shutdown checkpointer, reason
    logger.info "shutdown: #{reason.inspect}"
    logger.info "checkpointer: #{checkpointer.inspect}"
  end

  private

  def logger
    @_logger ||= Logger.new('consumer.log')
  end
end

if $0 == __FILE__
  Aws::KCLrb::KCLProcess.new(AdvancedConsumer.new).run
end
