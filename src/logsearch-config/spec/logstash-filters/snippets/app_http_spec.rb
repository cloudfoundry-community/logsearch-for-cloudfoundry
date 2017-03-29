# encoding: utf-8
require 'spec_helper'

describe "app-http.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-http.conf")}
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
        "@type" => "HttpStartStop",
        "parsed_json_field" => { "method" => "PUT", "status_code" => 200, "uri" => "/some/uri",
                                 "duration_ms" => 300,
                                 "peer_type" => "Client",
                                 "instance_id" => "abc", "instance_index" => 5 },
        "@message" => "some message"
    ) do

      it { expect(parsed_results.get("tags")).to eq ["http"] }

      it { expect(parsed_results.get("@message")).to eq "200 PUT /some/uri (300 ms)" } # constructed

      # keeps fields
      it { expect(parsed_results.get("parsed_json_field")["method"]).to eq "PUT" }
      it { expect(parsed_results.get("parsed_json_field")["peer_type"]).to eq "Client" }
      it { expect(parsed_results.get("parsed_json_field")["status_code"]).to eq 200 }
      it { expect(parsed_results.get("parsed_json_field")["uri"]).to eq "/some/uri" }
      it { expect(parsed_results.get("parsed_json_field")["duration_ms"]).to eq 300 }
      it { expect(parsed_results.get("parsed_json_field")["instance_id"]).to eq "abc" }
      it { expect(parsed_results.get("parsed_json_field")["instance_index"]).to eq 5 }
      it { expect(parsed_results.get("@type")).to eq "HttpStartStop" }

    end

  end

  # -- special cases
  describe "[instance_id] and [instance_index] skipped" do

    context "when empty instance_id" do
      when_parsing_log(
          "@type" => "HttpStartStop",
          "parsed_json_field" => { "method" => 1, "uri" => "/some/uri", "peer_type" => 1,
                                   "instance_id" => "", # empty
                                   "instance_index" => 0 },
          "@message" => "some message"
      ) do

        it { expect(parsed_results.get("parsed_json_field")["instance_id"]).to be_nil } # removes unnecessary field
        it { expect(parsed_results.get("parsed_json_field")["instance_index"]).to be_nil } # removes unnecessary field

      end
    end

    context "when missing instance_id" do
      when_parsing_log(
          "@type" => "HttpStartStop",
          "parsed_json_field" => { "method" => 1, "uri" => "/some/uri", "peer_type" => 1,
                                   "instance_index" => 0 }, # missing instance_id
          "@message" => "some message"
      ) do

        it { expect(parsed_results.get("parsed_json_field")["instance_id"]).to be_nil } # removes unnecessary field
        it { expect(parsed_results.get("parsed_json_field")["instance_index"]).to be_nil } # removes unnecessary field

      end
    end

  end

end
