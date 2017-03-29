# encoding: utf-8
require 'spec_helper'

describe "app-containermetric.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-containermetric.conf")}
      }
    CONFIG
  end

  describe "#if failed" do
    when_parsing_log(
        "@type" => "some type", # bad type
        "parsed_json_field" => { "field" => "value" },
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
        "@type" => "ContainerMetric",
        "parsed_json_field" => { "instance_index" => 5, "cpu_percentage" => 123, "memory_bytes" => 456, "disk_bytes" => 789 },
        "@cf" => { "app_id" => "abc" },
        "@message" => "some message"
    ) do

      it { expect(parsed_results.get("tags")).to eq ["containermetric"] }

      it { expect(parsed_results.get("@cf")["app_id"]).to eq "abc" } # keeps unchanged
      it { expect(parsed_results.get("@cf")["app_instance"]).to eq 5 }
      it { expect(parsed_results.get("parsed_json_field")["instance_index"]).to be_nil }

      it "keeps containermetric fields" do
        expect(parsed_results.get("parsed_json_field")["cpu_percentage"]).to eq 123
        expect(parsed_results.get("parsed_json_field")["memory_bytes"]).to eq 456
        expect(parsed_results.get("parsed_json_field")["disk_bytes"]).to eq 789
      end

      it { expect(parsed_results.get("@message")).to eq "cpu=123, memory=456, disk=789" }

      it { expect(parsed_results.get("@type")).to eq "ContainerMetric" } # keeps unchanged

    end
  end

  # -- special cases
  describe "[@cf][app_instance] skipped" do

    context "when empty app_id" do
      when_parsing_log(
          "@type" => "ContainerMetric",
          "parsed_json_field" => { "instance_index" => 5, "cpu_percentage" => 123, "memory_bytes" => 456, "disk_bytes" => 789 },
          "@cf" => { "app_id" => "" }, # empty
          "@message" => "some message"
      ) do

        it { expect(parsed_results.get("@cf")["app_id"]).to be_nil } # removes empty field
        it { expect(parsed_results.get("@cf")["app_instance"]).to be_nil } # doesn't set app_instance
        it { expect(parsed_results.get("parsed_json_field")["instance_index"]).to be_nil } # removes unnecessary field

      end
    end

    context "when missing app_id" do
      when_parsing_log(
          "@type" => "ContainerMetric",
          "parsed_json_field" => { "instance_index" => 5, "cpu_percentage" => 123, "memory_bytes" => 456, "disk_bytes" => 789 },
          "@cf" => { "some_field" => "" }, # missing app_id
          "@message" => "some message"
      ) do

        it { expect(parsed_results.get("@cf")["app_id"]).to be_nil } # missing
        it { expect(parsed_results.get("@cf")["app_instance"]).to be_nil } # doesn't set app_instance
        it { expect(parsed_results.get("parsed_json_field")["instance_index"]).to be_nil } # removes unnecessary field

      end
    end

  end

end
