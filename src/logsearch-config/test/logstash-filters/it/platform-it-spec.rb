# encoding: utf-8
require 'test/filter_test_helpers'

describe "Platform Integration Test spec" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG
  end

  describe "checks fields" do

    context "when @message in plain text format" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "vcap.consul-agent",
          "syslog_pri" => "14",
          "host" => "192.168.111.24:44577",
          "@message" => "[job=nfs_z1 index=0]      2016/07/08 10:23:22 [WARN] agent: Check 'service:routing-api' is now critical"
      ) do

        it "checks common fields" do
          expect(subject["@input"]).to eq "relp"
          expect(subject["@shipper"]["priority"]).to eq "14"
          expect(subject["@shipper"]["name"]).to eq "vcap.consul-agent_relp"
          expect(subject["@source"]["host"]).to eq "192.168.111.24:44577"
        end

        it "checks common fields overridden" do
          expect(subject["@source"]["component"]).to eq "consul-agent"
        end

        # TODO: verify other fields

      end
    end

  end

end
