require "test_utils"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do
  extend LogStash::RSpec

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-filters-common/src/10-syslog_standard.conf")}
      #{File.read("target/90-cloudfoundry-loggregator.conf")}
    }
  CONFIG

  describe "Parse Cloud Foundry loggregator messages with JSON" do
    sample("@type" => "syslog", "@message" => '276 <14>1 2014-05-20T20:40:49+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [App/0] - - {"@timestamp":"2014-05-20T20:40:49.907Z","message":"LowRequestRate 2014-05-20T15:44:58.794Z","@source.name":"watcher-bot-ppe","logger":"logsearch_watcher_bot.Program","level":"WARN"}') do
      insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_loggregator' ]
      insist { subject["@type"] } == "syslog"
      insist { subject["@timestamp"] } == Time.iso8601("2014-05-20T20:40:49.907Z").utc

      insist { subject["@source.host"] } == "loggregator"
      insist { subject["@source.app_id"] } == "d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc"

      insist { subject["log_source"] } == "App"
      insist { subject["log_source_id"] } == "0"

      insist { subject["message"] } == "LowRequestRate 2014-05-20T15:44:58.794Z"
      insist { subject["logger"] } == "logsearch_watcher_bot.Program"
      insist { subject["level"] } == "WARN"
      insist { subject["@source.name"] } == "watcher-bot-ppe"
    end

    sample("@type" => "syslog", "@message" => '272 <14>1 2014-05-20T20:34:49+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [App/0] - - {"@timestamp":"2014-05-20T20:34:49.830Z","Watcher_FinishedOn":"2014-05-20T15:44:58.794Z","@source.name":"watcher-bot-ppe","logger":"logsearch_watcher_bot.Program","level":"INFO"}') do
      insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_loggregator' ]
      insist { subject["@type"] } == "syslog"
      insist { subject["@timestamp"] } == Time.iso8601("2014-05-20T20:34:49.830Z").utc

      insist { subject["log_source"] } == "App"
      insist { subject["log_source_id"] } == "0"

      insist { subject["Watcher_FinishedOn"] } == "2014-05-20T15:44:58.794Z"
      insist { subject["logger"] } == "logsearch_watcher_bot.Program"
      insist { subject["level"] } == "INFO"
      insist { subject["@source.name"] } == "watcher-bot-ppe"
    end
  end

  describe "Parse Cloud Foundry loggregator messages with plain messages" do
    sample("@type" => "syslog", "@message" => '167 <14>1 2014-05-20T09:46:16+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [App/0] - - Updating AppSettings for /home/vcap/app/logsearch-watcher-bot.exe.config') do
      insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_loggregator' ]
      insist { subject["@type"] } == "syslog"
      insist { subject["@timestamp"] } == Time.iso8601("2014-05-20T09:46:16Z").utc

      insist { subject["@source.host"] } == "loggregator"
      insist { subject["@source.app_id"] } == "d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc"

      insist { subject["log_source"] } == "App"
      insist { subject["log_source_id"] } == "0"

      insist { subject["message"] } == "Updating AppSettings for /home/vcap/app/logsearch-watcher-bot.exe.config"
    end

    sample("@type" => "syslog", "@message" => '170 <14>1 2014-05-20T09:46:10+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [DEA] - - Starting app instance (index 0) with guid d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc') do
      insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_loggregator' ]
      insist { subject["@type"] } == "syslog"
      insist { subject["@timestamp"] } == Time.iso8601("2014-05-20T09:46:10Z").utc

      insist { subject["log_source"] } == "DEA"
      insist { subject["log_source_id"] }.nil? === true

      insist { subject["message"] } == "Starting app instance (index 0) with guid d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc"
    end

    sample("@type" => "syslog", "@message" => '94 <11>1 2014-05-20T09:46:07+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [App/0] - -') do
      insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_loggregator' ]
      insist { subject["@type"] } == "syslog"
      insist { subject["@timestamp"] } == Time.iso8601("2014-05-20T09:46:07Z").utc

      insist { subject["log_source"] } == "App"
      insist { subject["log_source_id"] } == "0"

      insist { subject["message"] }.nil? === true
    end
  end
end
