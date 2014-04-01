require "test_utils"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do
  extend LogStash::RSpec

  describe "parsing NatsStreamForwarder messages" do

    config <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-cf/logstash-filters-cf.conf")}
      }
    CONFIG

    sample("@message" => '<14>2014-04-01T06:04:55.213923+00:00 10.0.1.13 vcap.nats [job=vcap.nats index=0]  {"timestamp":1396332295.213669,"source":"NatsStreamForwarder","log_level":"info","message":"router.register","data":{"nats_message": "{\"host\":\"10.0.1.14\",\"port\":9022,\"uris\":[\"api.monitor-cloud.cityindextest5.co.uk\"],\"tags\":{\"component\":\"CloudController\"},\"index\":0,\"private_instance_id\":null}","reply_inbox":null}}', "@type" => "relp") do

      puts subject.inspect

      insist { subject["tags"] }.nil?
      
      insist { subject["@job.name"] } == "vcap_nats"
      insist { subject["message"] } == "router.register"

      #eg: "data":{"nats_message": "{\"host\":\"10.0.1.14\",\"port\":9022,\"uris\":[\"api.monitor-cloud.cityindextest5.co.uk\"],\"tags\":{\"component\":\"CloudController\"},\"index\":0,\"private_instance_id\":null}
      insist { subject["data"]["nats_message"]["host"] } == "10.0.1.14"
      insist { subject["data"]["nats_message"]["host"] } == "9022"
    end

  end

end
