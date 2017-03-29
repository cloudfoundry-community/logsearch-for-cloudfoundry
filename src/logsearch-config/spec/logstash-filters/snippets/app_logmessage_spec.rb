# encoding: utf-8
require 'spec_helper'

describe "app-logmessage.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-logmessage.conf")}
      }
    CONFIG
  end

  describe "#if failed" do
    when_parsing_log(
        "@type" => "some type", # bad type
        "parsed_json_field" => { "source_type" => "TestType", "source_instance" => "5", "message_type" => "OUT" },
        "@cf" => { "app_id" => "abc" },
        "@message" => "some message"
    ) do

      # tag is NOT set
      it { expect(parsed_results.get("tags")).to be_nil }

    end
  end

  # -- general case
  describe "#fields" do
    when_parsing_log(
        "@type" => "LogMessage",
        "parsed_json_field" => { "source_type" => "TestType", "source_instance" => "5", "message_type" => "OUT" },
        "@cf" => { "app_id" => "abc", "space" => "def" },
        "@message" => "some message"
    ) do

      it { expect(parsed_results.get("tags")).to eq ["logmessage"] }

      it { expect(parsed_results.get("@source")["type"]).to eq "TESTTYPE" } # uppercased

      it { expect(parsed_results.get("@cf")["app_id"]).to eq "abc" } # keeps unchanged
      it { expect(parsed_results.get("@cf")["app_instance"]).to eq 5 } # converted to int
      it { expect(parsed_results.get("parsed_json_field")["source_instance"]).to be_nil }

      it { expect(parsed_results.get("parsed_json_field")["message_type"]).to eq "OUT" } # keeps json fields
      it { expect(parsed_results.get("@cf")["space"]).to eq "def" } # keeps @cf fields

      it { expect(parsed_results.get("@message")).to eq "some message" }

    end
  end

  # -- special cases
  describe "drop/keep event" do

    context "when @message is useless (empty) - drop" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@message" => "" # empty message
      ) do

        # useless event was dropped
        it { expect(parsed_results).to be_nil}

      end
    end

    context "when @message is useless (blank) - drop" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@message" => "   " # blank message
      ) do

        # useless event was dropped
        it { expect(parsed_results).to be_nil}

      end
    end

    context "when @message is just missing - keep" do
      when_parsing_log(
          "@type" => "LogMessage"
          # no @message field at all
      ) do

        # event was NOT dropped
        it { expect(parsed_results).not_to be_nil}

      end
    end

  end

  describe "[@cf][app_instance] skipped" do

    context "when empty app_id" do
      when_parsing_log(
          "@type" => "LogMessage",
          "parsed_json_field" => { "source_type" => "TestType", "source_instance" => "5", "message_type" => "OUT" },
          "@cf" => { "app_id" => ""}, # empty app_id
          "@message" => "some message"
      ) do

        it { expect(parsed_results.get("@cf")["app_id"]).to be_nil } # removes empty field
        it { expect(parsed_results.get("@cf")["app_instance"]).to be_nil } # doesn't set app_instance
        it { expect(parsed_results.get("parsed_json_field")["source_instance"]).to be_nil } # removes unnecessary field


      end
    end

    context "when missing app_id" do
      when_parsing_log(
          "@type" => "LogMessage",
          "parsed_json_field" => { "source_type" => "TestType", "source_instance" => "5", "message_type" => "OUT" },
          "@cf" => { "field" => "value" }, # missing app_id
          "@message" => "some message"
      ) do

        it { expect(parsed_results.get("@cf")["app_id"]).to be_nil } # missing
        it { expect(parsed_results.get("@cf")["app_instance"]).to be_nil } # doesn't set app_instance
        it { expect(parsed_results.get("parsed_json_field")["source_instance"]).to be_nil } # removes unnecessary field

      end
    end

  end

end
