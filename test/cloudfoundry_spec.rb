require "test_utils"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do
  extend LogStash::RSpec

  config <<-CONFIG
    filter {
      #{File.read("target/100-cloudfoundry.conf")}
    }
  CONFIG

  describe "Parse Cloud Foundry messages shipped via Syslog or RELP" do
    samplemsg = '<6>2014-03-29T21:14:35.269841+00:00 10.0.1.13 vcap.hm9000.listener [job=vcap.hm9000.listener index=0] {"timestamp":1396127675.269712210,"process_id":16353,"source":"vcap.hm9000.listener","log_level":"info","message":"Received a heartbeat - {\"Heartbeats Pending Save\":\"1\"}","data":null}'

    sample("@type" => "relp", "@message" => samplemsg) do
      insist { subject["tags"] } == [ 'cloudfoundry' ]
      insist { subject["@type"] } == "relp_cf"
      insist { subject["@timestamp"] } == Time.iso8601("2014-03-29T21:14:35.269Z").utc

      insist { subject["@shipper.priority"] } == "6"
      insist { subject["@shipper.name"] } == "vcap_hm9000_listener_relp"

      insist { subject["@job.host"] } == "10.0.1.13"
      insist { subject["@job.name"] } == "vcap_hm9000_listener"
      insist { subject["@job.index"] } == "0"

      insist { subject["log_level"] } == "info"
      insist { subject["message"] } == "Received a heartbeat - {\"Heartbeats Pending Save\":\"1\"}"
    end

    sample("@type" => "relp", "@message" => "289 #{samplemsg}") do
      insist { subject["tags"] } == [ 'cloudfoundry' ]
      insist { subject["@type"] } == "relp_cf"
      insist { subject["@timestamp"] } == Time.iso8601("2014-03-29T21:14:35.269Z").utc

      insist { subject["@shipper.priority"] } == "6"
      insist { subject["@shipper.name"] } == "vcap_hm9000_listener_relp"

      insist { subject["@job.host"] } == "10.0.1.13"
      insist { subject["@job.name"] } == "vcap_hm9000_listener"
      insist { subject["@job.index"] } == "0"

      insist { subject["syslog_length"] } === 289

      insist { subject["log_level"] } == "info"
      insist { subject["message"] } == "Received a heartbeat - {\"Heartbeats Pending Save\":\"1\"}"
    end

    sample("@type" => "syslog", "@message" => '<14>2014-03-29T21:14:33.254640+00:00 10.0.1.13 vcap.nats [job=vcap.nats index=0] {"timestamp":1396127673.254181,"source":"NatsStreamForwarder","log_level":"info","message":"dea.advertise","data":{"nats_message": "{\"id\":\"0-67cf1ac3b917492ab441823225be23d5\",\"stacks\":[\"lucid64\",\"aws-ireland\"],\"available_memory\":2808,\"available_disk\":28928,\"app_id_to_count\":{\"c39a3631-4801-4775-8cfe-fe83d2a41d1f\":1,\"17d96217-9e57-4a78-9c0c-e3394c5d8aa4\":1,\"1d03006f-38b1-4012-a16a-69afc1af8b94\":1},\"placement_properties\":{\"zone\":\"default\"}}","reply_inbox":null}}') do
      insist { subject["tags"] } == [ 'cloudfoundry' ]
      insist { subject["@type"] } == "syslog_cf"
      insist { subject["@timestamp"] } == Time.iso8601("2014-03-29T21:14:33.254Z").utc

      insist { subject["@shipper.priority"] } == "14"
      insist { subject["@shipper.name"] } == "vcap_nats_syslog"

      insist { subject["@job.host"] } == "10.0.1.13"
      insist { subject["@job.name"] } == "vcap_nats"
      insist { subject["@job.index"] } == "0"

      insist { subject["log_level"] } == "info"
      insist { subject["message"] } == "dea.advertise"
    end

    sample("@type" => "syslog", "@message" => '<14>1 2014-03-29T21:14:33.254640+00:00 10.0.1.13 vcap.nats [job=vcap.nats index=0] {"timestamp":1396127673.254181,"source":"NatsStreamForwarder","log_level":"info","message":"dea.advertise","data":{"nats_message": "{\"id\":\"0-67cf1ac3b917492ab441823225be23d5\",\"stacks\":[\"lucid64\",\"aws-ireland\"],\"available_memory\":2808,\"available_disk\":28928,\"app_id_to_count\":{\"c39a3631-4801-4775-8cfe-fe83d2a41d1f\":1,\"17d96217-9e57-4a78-9c0c-e3394c5d8aa4\":1,\"1d03006f-38b1-4012-a16a-69afc1af8b94\":1},\"placement_properties\":{\"zone\":\"default\"}}","reply_inbox":null}}') do
      insist { subject["tags"] } == [ 'cloudfoundry' ]
      insist { subject["@type"] } == "syslog_cf"
      insist { subject["@timestamp"] } == Time.iso8601("2014-03-29T21:14:33.254Z").utc

      insist { subject["@shipper.priority"] } == "14"
      insist { subject["@shipper.name"] } == "vcap_nats_syslog"

      insist { subject["@job.host"] } == "10.0.1.13"
      insist { subject["@job.name"] } == "vcap_nats"
      insist { subject["@job.index"] } == "0"

      insist { subject["log_level"] } == "info"
      insist { subject["message"] } == "dea.advertise"

      insist { subject["syslog5424_ver"] } == 1
    end

    sample("@type" => "relp", "@message" => '<11>2014-06-03T18:54:10.392723+00:00 10.13.24.115 vcap.cloud_controller_ng.stderr [job=vcap.cloud_controller_ng.stderr index=0]  192.0.2.14, 10.13.17.18, 10.13.24.70 - - [03/Jun/2014 18:54:10] "GET /info HTTP/1.0" 200 283 0.0037') do
      insist { subject["tags"] } == [ 'cloudfoundry' ]
      insist { subject["@type"] } == "relp_cf"
      insist { subject["@timestamp"] } == Time.iso8601("2014-06-03T18:54:10.392Z").utc

      insist { subject["@shipper.priority"] } == "11"
      insist { subject["@shipper.name"] } == "vcap_cloud_controller_ng_stderr_relp"

      insist { subject["@job.host"] } == "10.13.24.115"
      insist { subject["@job.name"] } == "vcap_cloud_controller_ng_stderr"
      insist { subject["@job.index"] } == "0"

      insist { subject["message"] } == "192.0.2.14, 10.13.17.18, 10.13.24.70 - - [03/Jun/2014 18:54:10] \"GET /info HTTP/1.0\" 200 283 0.0037"
    end
  end

  describe "Parse NatsStreamForwarder specific messages from Cloud Foundry" do
    sample("@message" => '<14>2014-04-01T06:04:55.213923+00:00 10.0.1.13 vcap.nats [job=vcap.nats index=0]  {"timestamp":1396332295.213669,"source":"NatsStreamForwarder","log_level":"info","message":"router.register","data":{"nats_message": "{\"host\":\"10.0.1.14\",\"port\":9022,\"uris\":[\"api.monitor-cloud.cityindextest5.co.uk\"],\"tags\":{\"component\":\"CloudController\"},\"index\":0,\"private_instance_id\":null}","reply_inbox":null}}', "@type" => "relp") do
      insist { subject["tags"] } == [ 'cloudfoundry' ]
      
      insist { subject["@job.name"] } == "vcap_nats"
      insist { subject["message"] } == "router.register"

      #eg: "data":{"nats_message": "{\"host\":\"10.0.1.14\",\"port\":9022,\"uris\":[\"api.monitor-cloud.cityindextest5.co.uk\"],\"tags\":{\"component\":\"CloudController\"},\"index\":0,\"private_instance_id\":null}
      insist { subject["nats_message"]["host"] } == "10.0.1.14"
      insist { subject["nats_message"]["port"] } == 9022
    end
  end

  describe "Ensure Cloud Foundry messages that fail parsing are tagged appropriately" do
    sample("@type" => "relp", "@message" => '<14>2014-03-29T21:14:33.254640+00:00 10.0.1.13 vcap.nats - this message should fail the CF grok test') do
      insist { subject["tags"][0] } == "_grokparsefailure-cloudfoundry"
    end  
  end

  describe "relp or syslog messages that do not contain vcap are not parsed as cloudfoundry messages" do
    sample("@type" => "relp", "@message" => '<14>2014-03-29T21:14:33.254640+00:00 10.0.1.13 Foo') do
      subject["tags"].should be_nil
      insist { subject["@type"] } == "relp"
    end 
    sample("@type" => "syslog", "@message" => '<14>2014-03-29T21:14:33.254640+00:00 10.0.1.13 Foo') do
      subject["tags"].should be_nil
      insist { subject["@type"]} == "syslog"
    end 
  end

end
