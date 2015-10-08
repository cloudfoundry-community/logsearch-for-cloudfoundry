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
      #{File.read("vendor/logsearch-boshrelease/src/logsearch-filters-common/target/logstash-filters-default.conf")} 
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

    describe "attributes should go in @source" do

      sample(deepcopy(sample_msg)) do
        source = subject['@source']

        insist { source['job'] } == 'MetronAgent'
        insist { source['index'] } == 0
        insist { source['deployment'] } == 'CF'
        insist { source['ip'] } == '10.0.16.16'
        insist { source['job_name'] } == 'MetronAgent/0'
        insist { source['host'] } == '9903c27c-5209-4e38-a17b-3fb8693e6b7a'
        insist { source['name'] }.nil?
        insist { subject['host'] }.nil?
      end

    end # describe drop unused fields

    describe "When source['name'] doesn't exist" do
      msg = deepcopy(sample_msg)
      msg["attributes"].delete "name"

      sample(msg) do
        source = subject['@source']
        insist { source['job_name'] } == 'MetronAgent/0'
        insist { source['name'] }.nil?
      end

    end # describe drop unused fields

  end
end
