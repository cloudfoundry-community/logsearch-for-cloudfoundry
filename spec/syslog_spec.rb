require "test_utils"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do
  extend LogStash::RSpec

  describe "JSON app log" do

    config <<-CONFIG
      filter {
        #{File.read("config/filter.d/syslog.conf")}
      }
    CONFIG

    sample '+353 <14>1 2013-12-01T09:41:11+00:00 loggregator 66dcf62e-703d-49d4-b478-319e80f47fd8 App - - {"@timestamp":"2013-12-01T09:41:11.040Z","Name":"Latency CIAPI.PriceStream","Value":"0.085928","@source.name":"pivotal-us-east-1-push1","@source.lonlat":[-78.450065,38.130112],"logger":"Monitors.Common.LatencyMonitor","level":"INFO"}' do
      insist { subject["tags"] }.nil?
      insist { subject["syslog5424_pri"] } == "14"
      insist { subject["timestamp"] } == "2013-12-01T09:41"
    end

    sample '+353 <15>1 2013-12-01T09:41:11+00:00 loggregator 66dcf62e-703d-49d4-b478-319e80f47fd8 App - - {"@timestamp":"2013-12-01T09:41:11.040Z","Name":"Latency CIAPI.PriceStream","Value":"0.085928","@source.name":"pivotal-us-east-1-push1","@source.lonlat":[-78.450065,38.130112],"logger":"Monitors.Common.LatencyMonitor","level":"INFO"}' do
      insist { subject["tags"] }.nil?
      insist { subject["syslog5424_pri"] } == "15"
      insist { subject["timestamp"] } == "2013-12-01T09:41"
    end

    sample '+353 <16>1 2013-12-01T09:41:11+00:00 loggregator 66dcf62e-703d-49d4-b478-319e80f47fd8 App - - {"@timestamp":"2013-12-01T09:41:11.040Z","Name":"Latency CIAPI.PriceStream","Value":"0.085928","@source.name":"pivotal-us-east-1-push1","@source.lonlat":[-78.450065,38.130112],"logger":"Monitors.Common.LatencyMonitor","level":"INFO"}' do
      insist { subject["tags"] }.nil?
      insist { subject["syslog5424_pri"] } == "16"
      insist { subject["timestamp"] } == "2013-12-01T09:41"
    end

    sample '+353 <17>1 2013-12-01T09:41:11+00:00 loggregator 66dcf62e-703d-49d4-b478-319e80f47fd8 App - - {"@timestamp":"2013-12-01T09:41:11.040Z","Name":"Latency CIAPI.PriceStream","Value":"0.085928","@source.name":"pivotal-us-east-1-push1","@source.lonlat":[-78.450065,38.130112],"logger":"Monitors.Common.LatencyMonitor","level":"INFO"}' do
      insist { subject["tags"] }.nil?
      insist { subject["syslog5424_pri"] } == "17"
      insist { subject["timestamp"] } == "2013-12-01T09:41"
    end
  end

end