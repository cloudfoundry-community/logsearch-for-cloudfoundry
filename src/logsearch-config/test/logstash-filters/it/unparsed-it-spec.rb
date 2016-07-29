# encoding: utf-8
require 'test/filter_test_helpers'

describe "Undefined logs IT" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG
  end

  describe "undefined log" do

    when_parsing_log(
        "@type" => "relp",
        "syslog_program" => "some-program", # not a platform log
        "syslog_pri" => "14",
        "syslog_severity_code" => 3,
        "host" => "192.168.111.24:44577",
        "@message" => "Some message" # not a platform log
    ) do

      # parsing error
      it { expect(subject["@tags"]).to include "fail/cloudfoundry/platform/grok" }

      # fields
      it "should set common fields" do
        expect(subject["@input"]).to eq "relp"
        expect(subject["@shipper"]["priority"]).to eq "14"
        expect(subject["@shipper"]["name"]).to eq "some-program_relp"
        expect(subject["@source"]["host"]).to eq "192.168.111.24:44577"
        expect(subject["@source"]["name"]).to be_nil
        expect(subject["@source"]["instance"]).to be_nil
        expect(subject["@source"]["component"]).to eq "some-program"
        expect(subject["@type"]).to eq "relp"

        expect(subject["@metadata"]["index"]).to eq "unparsed"
      end

      it "should set mandatory fields" do
        expect(subject["@message"]).to eq "Some message"
        expect(subject["@level"]).to eq "ERROR"
      end

    end

  end

end
