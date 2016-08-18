# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

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
      it { expect(subject["tags"]).to be_nil }

    end
  end

  # -- general case
  describe "#fields" do

    context "when HttpStart" do
      when_parsing_log(
          "@type" => "HttpStart",
          "parsed_json_field" => { "method" => "GET", "uri" => "/some/uri", "peer_type" => "Client",
                                   "instance_id" => "abc", "instance_index" => 5 },
          "@message" => "some message"
      ) do

        it { expect(subject["tags"]).to eq ["http"] }

        it { expect(subject["@message"]).to eq "GET /some/uri" } # constructed

        # keeps fields
        it { expect(subject["parsed_json_field"]["method"]).to eq "GET" }
        it { expect(subject["parsed_json_field"]["peer_type"]).to eq "Client" }
        it { expect(subject["parsed_json_field"]["uri"]).to eq "/some/uri" }
        it { expect(subject["parsed_json_field"]["instance_id"]).to eq "abc" }
        it { expect(subject["parsed_json_field"]["instance_index"]).to eq 5 }
        it { expect(subject["@type"]).to eq "HttpStart" }

      end
    end

    context "when HttpStop" do
      when_parsing_log(
          "@type" => "HttpStop",
          "parsed_json_field" => { "status_code" => 200, "uri" => "/some/uri", "peer_type" => "Server",
                                   "instance_id" => "abc", "instance_index" => 5 },
          "@message" => "some message"
      ) do

        it { expect(subject["tags"]).to eq ["http"] }

        it { expect(subject["@message"]).to eq "200 /some/uri" } # constructed

        # keeps fields
        it { expect(subject["parsed_json_field"]["peer_type"]).to eq "Server" }
        it { expect(subject["parsed_json_field"]["status_code"]).to eq 200 }
        it { expect(subject["parsed_json_field"]["uri"]).to eq "/some/uri" }
        it { expect(subject["parsed_json_field"]["instance_id"]).to eq "abc" }
        it { expect(subject["parsed_json_field"]["instance_index"]).to eq 5 }
        it { expect(subject["@type"]).to eq "HttpStop" }

      end
    end

    context "when HttpStartStop (and NA peer_type)" do
      when_parsing_log(
          "@type" => "HttpStartStop",
          "parsed_json_field" => { "method" => "PUT", "status_code" => 200, "uri" => "/some/uri",
                                   "duration_ms" => 300,
                                   "peer_type" => "Client",
                                   "instance_id" => "abc", "instance_index" => 5 },
          "@message" => "some message"
      ) do

        it { expect(subject["tags"]).to eq ["http"] }

        it { expect(subject["@message"]).to eq "200 PUT /some/uri (300 ms)" } # constructed

        # keeps fields
        it { expect(subject["parsed_json_field"]["method"]).to eq "PUT" }
        it { expect(subject["parsed_json_field"]["peer_type"]).to eq "Client" }
        it { expect(subject["parsed_json_field"]["status_code"]).to eq 200 }
        it { expect(subject["parsed_json_field"]["uri"]).to eq "/some/uri" }
        it { expect(subject["parsed_json_field"]["duration_ms"]).to eq 300 }
        it { expect(subject["parsed_json_field"]["instance_id"]).to eq "abc" }
        it { expect(subject["parsed_json_field"]["instance_index"]).to eq 5 }
        it { expect(subject["@type"]).to eq "HttpStartStop" }

      end
    end

  end

  # -- special cases
  describe "[instance_id] and [instance_index] skipped" do

    context "when empty instance_id" do
      when_parsing_log(
          "@type" => "HttpStop",
          "parsed_json_field" => { "method" => 1, "uri" => "/some/uri", "peer_type" => 1,
                                   "instance_id" => "", # empty
                                   "instance_index" => 0 },
          "@message" => "some message"
      ) do

        it { expect(subject["parsed_json_field"]["instance_id"]).to be_nil } # removes unnecessary field
        it { expect(subject["parsed_json_field"]["instance_index"]).to be_nil } # removes unnecessary field

      end
    end

    context "when missing instance_id" do
      when_parsing_log(
          "@type" => "HttpStop",
          "parsed_json_field" => { "method" => 1, "uri" => "/some/uri", "peer_type" => 1,
                                   "instance_index" => 0 }, # missing instance_id
          "@message" => "some message"
      ) do

        it { expect(subject["parsed_json_field"]["instance_id"]).to be_nil } # removes unnecessary field
        it { expect(subject["parsed_json_field"]["instance_index"]).to be_nil } # removes unnecessary field

      end
    end

  end

end
