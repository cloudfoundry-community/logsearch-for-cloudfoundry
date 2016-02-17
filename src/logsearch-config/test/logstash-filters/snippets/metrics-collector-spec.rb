# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"
require 'tempfile'
require 'json'

module Enumerable
  def does_not_include?(item)
    !include?(item)
  end
end

def deepcopy(o)
  Marshal.load(Marshal.dump(o))
end

  sample_msg = JSON.parse(<<JSON
{
    "version": "1.0",
    "host": "9903c27c-5209-4e38-a17b-3fb8693e6b7a",
    "level": 1,
    "facility": "gelf-rb",
    "key": "MetronAgent.memoryStats.numBytesAllocated",
    "value": 641952,
    "file": "/var/vcap/data/packages/collector/c9f77b6f84d393722c82fd081a46b8fd404c3459.1-95133dca8391414266fd8ca8eec5db9e4a26fc1d/lib/collector/historian/gelf.rb",
    "line": 14,
    "@version": "1",
    "@timestamp": "2015-09-22T05:25:49.000Z",
    "source_host": "127.0.0.1",
    "attributes": {
      "job": "MetronAgent",
      "index": 0,
      "deployment": "CF",
      "ip": "10.0.16.16",
      "name": "MetronAgent/0"
    },
    "tags": [
      "collector"
    ],
    "@type": "gelf",
    "@message": "MetronAgent.memoryStats.numBytesAllocated 641952"
  }
JSON
)

describe LogStash::Filters::Grok do

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-boshrelease/src/logsearch-config/target/logstash-filters-default.conf")}
      #{File.read("target/logstash-filters-default.conf")}
    }
  CONFIG

  describe "Collector events" do

     describe "drop unused fields" do

      sample(deepcopy(sample_msg)) do

        insist { subject["version"] }.nil?
        insist { subject["level"] }.nil?
        insist { subject["facility"] }.nil?
        insist { subject["file"] }.nil?
        insist { subject["line"] }.nil?
        insist { subject["source_host"] }.nil?

      end

    end # describe drop unused fields

    describe "data should go in [metric]" do

      sample(deepcopy(sample_msg)) do
        metric = subject['metric']

        insist { metric['key'] } == 'MetronAgent.memoryStats.numBytesAllocated'
        insist { metric['value_int'] } == 641952
        insist { metric['value_float'] }.nil?

        insist { subject["key"] }.nil?
        insist { subject["value"] }.nil?
      end

      msg = deepcopy(sample_msg)
      msg["value"] = "0.9583333333333334"

      sample(msg) do
        metric = subject['metric']
        insist { metric['key'] } == 'MetronAgent.memoryStats.numBytesAllocated'
        insist { metric['value_int'] }.nil?
        insist { metric['value_float'] } == 0.9583333333333334
      end

    end # describe data should go in [metric]

    describe "attributes should go in @source" do

      sample(deepcopy(sample_msg)) do
        source = subject['@source']

        insist { source['name'] } == 'MetronAgent/0'
        insist { source['component'] } == 'MetronAgent'
        insist { source['instance'] } == 0
        insist { source['deployment'] } == 'CF'
        insist { source['host'] } == '10.0.16.16'

        insist { subject["attributes"] }.nil?
      end

    end #describe attributes should go in @source

    describe "When source['name'] doesn't exist" do
      msg = deepcopy(sample_msg)
      msg["attributes"].delete "name"

      sample(msg) do
        source = subject['@source']
        insist { source['name'] } == 'MetronAgent/0'
      end

    end # describe When source['name'] doesn't exist

    describe "index and type" do

      sample(deepcopy(sample_msg)) do

        insist { subject["@metadata"]["index"] } == "platform"
        insist { subject["@metadata"]["type"] } == "metric"
        insist { subject["tags"] } == [ "collector", "metric" ]

      end

    end # describe index and type

  end
end
