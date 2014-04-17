require "test_utils"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do
  extend LogStash::RSpec

  describe "CloudFoundry message parsing failures" do

    config <<-CONFIG
      filter {
        #{File.read("target/100-cloudfoundry.conf")}
      }
    CONFIG

    sample("@type" => "relp", "@message" => '<14>2014-03-29T21:14:33.254640+00:00 10.0.1.13 vcap.nats - this message should fail the CF grok test') do
      insist { subject["tags"][0]} === "_cfparsefailure"
    end  
  end

end
