# encoding: utf-8
require 'test/filter_test_helpers'

describe "UAA spec" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/uaa.conf")}
      }
    CONFIG
  end

  describe "General event" do
    when_parsing_log(
      "@type" => "syslog_cf",
      "syslog_program" => "vcap.uaa",
      "@message" => "[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  INFO --- Audit: ClientAuthenticationSuccess ('Client authentication success'): principal=cf, origin=[remoteAddress=64.78.155.208, clientId=cf], identityZoneId=[uaa]"
    ) do

      # Check that @message is parsed with no errors
      it "does not include grok fail tag" do
        expect(subject["tags"]).not_to include "fail/cloudfoundry/uaa/grok"
      end

      # Check fields
      it "sets @message from grok" do
        expect(subject["@message"]).to eq "ClientAuthenticationSuccess ('Client authentication success')"
      end

      it "sets @level from grok" do
        expect(subject["@level"]).to eq "INFO"
      end

      it "sets geoip for remoteAddress" do
        expect(subject["geoip"]).not_to be_nil
        expect(subject["geoip"]["ip"]).to eq "64.78.155.208"
      end

      it "sets [uaa] fields" do
        expect(subject["uaa"]["pid"]).to eq 15178
        expect(subject["uaa"]["thread_name"]).to eq "http-bio-8080-exec-14"
        expect(subject["uaa"]["timestamp"]).to eq "2016-07-05 04:02:18.245"
        expect(subject["uaa"]["type"]).to eq "ClientAuthenticationSuccess"
        expect(subject["uaa"]["remote_address"]).to eq "64.78.155.208"
        expect(subject["uaa"]["data"]).to eq "Client authentication success"
        expect(subject["uaa"]["principal"]).to eq "cf"
        expect(subject["uaa"]["origin"]).to eq ["remoteAddress=64.78.155.208", "clientId=cf"]
        expect(subject["uaa"]["identity_zone_id"]).to eq "uaa"
      end

      it "sets [@source][component]" do
        expect(subject["@source"]["component"]).to eq "uaa"
      end

      it "sets @type" do
        expect(subject["@type"]).to eq "uaa_cf"
      end

      it "sets 'uaa' tag" do
        expect(subject["tags"]).to include "uaa"
      end

    end
  end

  describe "PrincipalAuthFailure event" do
    when_parsing_log(
        "@type" => "syslog_cf",
        "syslog_program" => "vcap.uaa",
        "@message" => "[2016-07-06 09:18:43.397] uaa - 15178 [http-bio-8080-exec-6] ....  INFO --- Audit: PrincipalAuthenticationFailure ('null'): principal=admin, origin=[82.209.244.50], identityZoneId=[uaa]"
    ) do

      # Check that @message is parsed with no errors
      it "not include grok fail tag" do
        expect(subject["tags"]).not_to include "fail/cloudfoundry/uaa/grok"
      end

      # Check fields
      it "sets @message from grok" do
        expect(subject["@message"]).to eq "PrincipalAuthenticationFailure ('null')"
      end

      it "sets @level from grok" do
        expect(subject["@level"]).to eq "INFO"
      end

      it "sets geoip for remoteAddress" do
        expect(subject["geoip"]).not_to be_nil
        expect(subject["geoip"]["ip"]).to eq "82.209.244.50"
      end

      it "sets [uaa] fields" do
        expect(subject["uaa"]["pid"]).to eq 15178
        expect(subject["uaa"]["thread_name"]).to eq "http-bio-8080-exec-6"
        expect(subject["uaa"]["timestamp"]).to eq "2016-07-06 09:18:43.397"
        expect(subject["uaa"]["type"]).to eq "PrincipalAuthenticationFailure"
        expect(subject["uaa"]["remote_address"]).to eq "82.209.244.50"
        expect(subject["uaa"]["data"]).to eq "null"
        expect(subject["uaa"]["principal"]).to eq "admin"
        expect(subject["uaa"]["origin"]).to eq ["82.209.244.50"]
        expect(subject["uaa"]["identity_zone_id"]).to eq "uaa"
      end

      it "sets [@source][component]" do
        expect(subject["@source"]["component"]).to eq "uaa"
      end

      it "sets @type" do
        expect(subject["@type"]).to eq "uaa_cf"
      end

      it "sets 'uaa' tag" do
        expect(subject["tags"]).to include "uaa"
      end

    end
  end

  describe "Failed grok" do
    when_parsing_log(
        "@type" => "syslog_cf",
        "syslog_program" => "vcap.uaa",
        "@message" => "Some incorrect message that doesn't match UAA grok patterns"
    ) do

      # Check that fail tag is set
      it "include grok fail tag" do
        expect(subject["tags"]).to include "fail/cloudfoundry/uaa/grok"
      end

      # Check @message is the same as before parsing
      it "doesn't change @message" do
        expect(subject["@message"]).to eq "Some incorrect message that doesn't match UAA grok patterns"
      end

    end
  end
end
