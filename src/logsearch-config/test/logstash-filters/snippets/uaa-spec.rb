# encoding: utf-8
require 'test/filter_test_helpers'

describe "uaa.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/uaa.conf")}
      }
    CONFIG
  end

  # -- test snippet's 'if' condition --
  describe "#if" do

    describe "passed" do
      when_parsing_log(
          "@source" => {"component" => "vcap.uaa"}, # good value
          "@message" => "Some message"
      ) do

        # uaa tag set => 'if' succeeded
        it { expect(subject["tags"]).to include "uaa" }

      end
    end

    describe "failed" do
      when_parsing_log(
          "@source" => {"component" => "some value"}, # bad value
          "@message" => "Some message"
      ) do

        # no tags set => 'if' failed
        it { expect(subject["tags"]).to be_nil }

        it { expect(subject["@source"]["component"]).to eq "some value" } # keeps unchanged
        it { expect(subject["@message"]).to eq "Some message" } # keeps unchanged

      end
    end

  end

  describe "when message is" do

    context "general UAA event" do
      when_parsing_log(
        "@source" => {"component" => "vcap.uaa"},
        # general UAA event
        "@message" => "[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  INFO --- Audit: ClientAuthenticationSuccess ('Client authentication success'): principal=cf, origin=[remoteAddress=64.78.155.208, clientId=cf], identityZoneId=[uaa]"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).not_to include "fail/cloudfoundry/uaa/grok" }

        # fields

        it { expect(subject["@source"]["component"]).to eq "uaa" }
        it { expect(subject["tags"]).to include "uaa" }

        it "should set fields from grok" do
          expect(subject["@message"]).to eq "ClientAuthenticationSuccess ('Client authentication success')"
          expect(subject["@level"]).to eq "INFO"
        end

        it "should set geoip for remoteAddress" do
          expect(subject["geoip"]).not_to be_nil
          expect(subject["geoip"]["ip"]).to eq "64.78.155.208"
        end

        it "should set [uaa] fields" do
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

      end
    end

    describe "PrincipalAuthFailure event" do
      when_parsing_log(
          "@source" => {"component" => "vcap.uaa"},
          # PrincipalAuthFailure event
          "@message" => "[2016-07-06 09:18:43.397] uaa - 15178 [http-bio-8080-exec-6] ....  INFO --- Audit: " +
              "PrincipalAuthenticationFailure ('null'): principal=admin, origin=[82.209.244.50], identityZoneId=[uaa]"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).not_to include "fail/cloudfoundry/uaa/grok" }

        # fields
        it { expect(subject["@source"]["component"]).to eq "uaa" }
        it { expect(subject["tags"]).to include "uaa" }

        it "should set fields from grok" do
          expect(subject["@message"]).to eq "PrincipalAuthenticationFailure ('null')"
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

      end
    end

    describe "bad format" do
      when_parsing_log(
          "@source" => {"component" => "vcap.uaa"},
          "@message" => "Some message" # bad format
      ) do

        # get parsing error
        it { expect(subject["tags"]).to include "fail/cloudfoundry/uaa/grok" }

        # fields
        it { expect(subject["@source"]["component"]).to eq "uaa" }
        it { expect(subject["tags"]).to include "uaa" }

        it { expect(subject["@message"])
          .to eq "Some message" } # the same as before parsing

      end
    end

  end
end
