# encoding: utf-8
require 'spec_helper'

describe "app-valuemetric.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-valuemetric.conf")}
      }
    CONFIG
  end

  describe "#if failed" do
    when_parsing_log(
        "@type" => "some type", # bad type
        "parsed_json_field" => { "field" => "value" },
        "@message" => "some message"
    ) do

      # tag is NOT set
      it { expect(parsed_results.get("tags")).to be_nil }

    end
  end

  # -- general case
  describe "#fields" do
    when_parsing_log(
        "@type" => "ValueMetric",
        "parsed_json_field" => { "name" => "abc", "value" => 123.456, "unit" => "def" },
        "@message" => "some message"
    ) do

      it { expect(parsed_results.get("tags")).to eq ["valuemetric"] }

      it { expect(parsed_results.get("@message")).to eq "abc = 123.456 (def)" }
      it { expect(parsed_results.get("parsed_json_field")["name"]).to eq "abc" }
      it { expect(parsed_results.get("parsed_json_field")["value"]).to eq 123.456 }
      it { expect(parsed_results.get("parsed_json_field")["unit"]).to eq "def" }

      it { expect(parsed_results.get("@type")).to eq "ValueMetric" } # keeps unchanged

    end
  end

end
