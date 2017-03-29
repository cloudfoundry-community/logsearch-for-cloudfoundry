# encoding: utf-8
require 'spec_helper'

describe "setup.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/setup.conf")}
      }
    CONFIG
  end

  describe "when message" do
    context "is useless (empty)" do
      when_parsing_log(
          "@message" => "" # empty
      ) do

        # event is dropped
        it { expect(parsed_results).to be_nil}

      end
    end

    context "is useless (blank)" do
      when_parsing_log(
          "@message" => "    " # blank
      ) do

        # event is dropped
        it { expect(parsed_results).to be_nil}

      end
    end

    context "contains unicode (\u0000)" do
      when_parsing_log(
          "@message" => "a\u0000bc" # unicode
      ) do

        # unicode removed
        it { expect(parsed_results.get("@message")).to eq "abc" }

      end
    end

    context "is OK" do
      when_parsing_log(
          "@type" => "some-type",
          "syslog_program" => "some-program",
          "syslog_pri" => 5,
          "@message" => "Some message" # OK
      ) do

        # fields
        it { expect(parsed_results.get("@index_type")).to eq "platform" }
        it { expect(parsed_results.get("@metadata")["index"]).to eq "platform" }
        it { expect(parsed_results.get("@input")).to eq "some-type" }
        it { expect(parsed_results.get("@shipper")["priority"]).to eq 5 }
        it { expect(parsed_results.get("@shipper")["name"]).to eq "some-program_some-type" }
        it { expect(parsed_results.get("@source")["component"]).to eq "some-program" }

      end
    end

  end

  describe "when index is " do
    context "app" do
      when_parsing_log(
          "syslog_program" => "doppler", # app logs
          "@message" => "Some message"
      ) do

        # fields
        it { expect(parsed_results.get("@index_type")).to eq "app" }
        it { expect(parsed_results.get("@metadata")["index"]).to eq "app" }

      end
    end

    context "platform" do
      when_parsing_log(
          "syslog_program" => "not doppler", # platform logs
          "@message" => "Some message"
      ) do

        # fields
        it { expect(parsed_results.get("@index_type")).to eq "platform" }
        it { expect(parsed_results.get("@metadata")["index"]).to eq "platform" }

      end
    end

  end

end
