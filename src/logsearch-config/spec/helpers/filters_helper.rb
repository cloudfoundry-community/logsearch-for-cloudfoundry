# encoding: utf-8
require 'json'
require 'logstash-core/logstash-core'
require 'logstash/util/loggable'
require 'logstash/filters/alter'
require 'logstash/pipeline'

module LogStash::Environment
  # running the grok code outside a logstash package means
  # LOGSTASH_HOME will not be defined, so let's set it here
  # before requiring the grok filter
  unless self.const_defined?(:LOGSTASH_HOME)
    LOGSTASH_HOME = File.expand_path("../../../", __FILE__)
  end

  # also :pattern_path method must exist so we define it too
  unless self.method_defined?(:pattern_path)
    def pattern_path(path)
      ::File.join(LOGSTASH_HOME, "patterns", path)
    end
  end
end

module Helpers
  module FilterHelper
    class LogStashPipeline
      class << self
        def instance=(instance)
          @the_pipeline = instance
        end

        def instance
          @the_pipeline
        end

        private :new
      end
    end

    def load_filters(filters)
      pipeline = LogStash::Pipeline.new(filters)
      pipeline.instance_eval { @filters.each(&:register) }

      LogStashPipeline.instance = pipeline
    end

    def when_parsing_log(sample_event, &block)
      name = ""
      if sample_event.is_a?(String)
        name = sample_event
        sample_event = { '@type' => 'syslog', '@message' => sample_event }
      else
        name = LogStash::Json.dump(sample_event)
      end

      name = name[0..200] + "..." if name.length > 200

      describe "[\"#{name}\"]" do

        before(:all) do
          results = []
          # filter call the block on all filtered events, included new events added by the filter
          event = LogStash::Event.new(sample_event)
          LogStashPipeline.instance.filter(event) { |filtered_event| results << filtered_event }
          # flush makes sure to empty any buffered events in the filter
          LogStashPipeline.instance.flush_filters(:final => true) { |flushed_event| results << flushed_event }

          @parsed_results = results.select { |e| !e.cancelled? }
        end

        subject(:parsed_results) { @parsed_results.first }

        describe("", &block)
      end

    end
  end
end
