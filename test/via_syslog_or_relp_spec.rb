require "test_utils"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do
  extend LogStash::RSpec

  describe "CloudFoundry messages shipped via Syslog or RELP" do

    config <<-CONFIG
      filter {
        #{File.read("target/100-cloudfoundry.conf")}
      }
    CONFIG

    sample("@type" => "relp", "@message" => '<6>2014-03-29T21:14:35.269841+00:00 10.0.1.13 vcap.hm9000.listener [job=vcap.hm9000.listener index=0] {"timestamp":1396127675.269712210,"process_id":16353,"source":"vcap.hm9000.listener","log_level":"info","message":"Received a heartbeat - {\"Heartbeats Pending Save\":\"1\"}","data":null}') do

      insist { subject["@type"] } == "relp_cf"
      insist { subject["tags"] }.nil?
      
      insist { subject["@timestamp"] } == Time.iso8601("2014-03-29T21:14:35.269Z").utc

      insist { subject["@shipper.priority"] } == "6"
      insist { subject["@shipper.name"] } == "vcap_hm9000_listener_relp"

      insist { subject["@job.host"] } == "10.0.1.13"
      insist { subject["@job.name"] } == "vcap_hm9000_listener"
      insist { subject["@job.index"] } == "0"

      insist { subject["log_level"] } == "info"
      insist { subject["message"] } == "Received a heartbeat - {\"Heartbeats Pending Save\":\"1\"}"
      
    end

    sample("@type" => "syslog", "@message" => '<14>2014-03-29T21:14:33.254640+00:00 10.0.1.13 vcap.nats [job=vcap.nats index=0] {"timestamp":1396127673.254181,"source":"NatsStreamForwarder","log_level":"info","message":"dea.advertise","data":{"nats_message": "{\"id\":\"0-67cf1ac3b917492ab441823225be23d5\",\"stacks\":[\"lucid64\",\"aws-ireland\"],\"available_memory\":2808,\"available_disk\":28928,\"app_id_to_count\":{\"c39a3631-4801-4775-8cfe-fe83d2a41d1f\":1,\"17d96217-9e57-4a78-9c0c-e3394c5d8aa4\":1,\"1d03006f-38b1-4012-a16a-69afc1af8b94\":1},\"placement_properties\":{\"zone\":\"default\"}}","reply_inbox":null}}') do

      insist { subject["@type"] } == "syslog_cf"
      insist { subject["tags"] }.nil?
      
      insist { subject["@timestamp"] } == Time.iso8601("2014-03-29T21:14:33.254Z").utc

      insist { subject["@shipper.priority"] } == "14"
      insist { subject["@shipper.name"] } == "vcap_nats_syslog"

      insist { subject["@job.host"] } == "10.0.1.13"
      insist { subject["@job.name"] } == "vcap_nats"
      insist { subject["@job.index"] } == "0"

      insist { subject["log_level"] } == "info"
      insist { subject["message"] } == "dea.advertise"
      
    end



  end

end
