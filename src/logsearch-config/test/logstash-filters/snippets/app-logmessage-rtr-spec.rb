# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

describe "app-logmessage-rtr.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-logmessage-rtr.conf")}
      }
    CONFIG
  end

  # -- general case
  describe "#fields when message is" do

    context "RTR format" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          # rtr format
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).to eq ["logmessage-rtr"] } # no fail tag

        # fields
        it { expect(subject["@message"]).to eq "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n" }
        it { expect(subject["@level"]).to eq "INFO" }

        it "sets [rtr] fields" do
          expect(subject["rtr"]["hostname"]).to eq "parser.64.78.234.207.xip.io"
          expect(subject["rtr"]["timestamp"]).to eq "15/07/2016:09:26:25 +0000"
          expect(subject["rtr_time"]).to be_nil
          expect(subject["rtr"]["verb"]).to eq "GET"
          expect(subject["rtr"]["path"]).to eq "/http"
          expect(subject["rtr"]["http_spec"]).to eq "HTTP/1.1"
          expect(subject["rtr"]["status"]).to eq 200
          expect(subject["rtr"]["request_bytes_received"]).to eq 0
          expect(subject["rtr"]["body_bytes_sent"]).to eq 1413
          expect(subject["rtr"]["referer"]).to eq "-"
          expect(subject["rtr"]["http_user_agent"]).to eq "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
          expect(subject["rtr"]["x_forwarded_for"]).to eq ["82.209.244.50", "192.168.111.21"]
          expect(subject["rtr"]["x_forwarded_proto"]).to eq "http"
          expect(subject["rtr"]["vcap_request_id"]).to eq "831e54f1-f09f-4971-6856-9fdd502d4ae3"
          expect(subject["rtr"]["response_time_sec"]).to eq 0.005328859
          # calculated values
          expect(subject["rtr"]["remote_addr"]).to eq "82.209.244.50"
          expect(subject["rtr"]["response_time_ms"]).to eq 5
        end

        it "sets geoip for [rtr][remote_addr]" do
          expect(subject["geoip"]).not_to be_nil
          expect(subject["geoip"]["ip"]).to eq "82.209.244.50"
        end

      end
    end

    context "bad format" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => {"type" => "RTR"},
          "@level" => "SOME LEVEL",
          "@message" => "Some message of wrong format" # bad format
      ) do

        # get parsing error
        it { expect(subject["tags"]).to eq ["logmessage-rtr", "fail/cloudfoundry/app-rtr/grok"] }

        # fields
        it { expect(subject["@message"]).to eq "Some message of wrong format" } # keeps unchanged
        it { expect(subject["@level"]).to eq "SOME LEVEL" } # keeps unchanged

        it { expect(subject["rtr"]).to be_nil }
        it { expect(subject["geoip"]).to be_nil }

      end
    end

  end

  # -- special cases
  describe "when HTTP status" do

    context "<400 (INFO @level)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" " +
              "200" + # HTTP status <400
              " 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(subject["@level"]).to eq "INFO" }

      end
    end

    context "=400 (ERROR @level)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" " +
              "400" + # HTTP status =400
              " 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(subject["@level"]).to eq "ERROR" }

      end
    end

    context ">400 (ERROR @level)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" " +
              "401" + # HTTP status >400
              " 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(subject["@level"]).to eq "ERROR" }

      end
    end

  end

  describe "when [rtr][x_forwarded_for]" do

    context "contains quotes & whitespaces" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 " +
              "x_forwarded_for:\"\"  82.209.244.50 \",     192.168.111.21 \"" +  # contains quotes & whitespaces
              " x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it "removes quotes and whitespaces and split" do
          expect(subject["rtr"]["x_forwarded_for"]).to eq ["82.209.244.50", "192.168.111.21"]
        end

      end
    end

    context "blank value" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 " +
              "x_forwarded_for:\"    \"" +  # blank value
              " x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(subject["rtr"]["x_forwarded_for"]).to eq [] } # empty

      end
    end

  end

  describe "when [rtr][remote_addr]" do

    context "has ip format" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 " +
              "x_forwarded_for:\"82.209.244.50\"" + # ip format
              " x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(subject["rtr"]["remote_addr"]).to eq "82.209.244.50" }

        it "sets geoip for [rtr][remote_addr]" do
          expect(subject["geoip"]).not_to be_nil
          expect(subject["geoip"]["ip"]).to eq "82.209.244.50"
        end

      end
    end

    context "has bad format" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 " +
              "x_forwarded_for:\"bad_format, 82.209.244.50\"" + # bad format
              " x_forwarded_proto:\"http\" vcap_request_id:831e54f1-f09f-4971-6856-9fdd502d4ae3 response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(subject["rtr"]["remote_addr"]).to eq "bad_format" }

      end
    end

  end

  describe "when NOT rtr case" do

    context "(bad @type)" do
      when_parsing_log(
          "@type" => "Some type", # bad value
          "@source" => {"type" => "RTR"},
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no rtr tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "(bad [@source][type])" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => {"type" => "Bad value"}, # bad value
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no rtr tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

  end

end
