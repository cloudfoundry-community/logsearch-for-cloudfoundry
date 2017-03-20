# encoding: utf-8
require 'spec_helper'

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
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /some/http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        # no parsing errors
        it { expect(parsed_results.get("tags")).to eq ["logmessage-rtr"] } # no fail tag

        # fields
        it { expect(parsed_results.get("@message")).to eq "200 GET /some/http (5 ms)" }
        it { expect(parsed_results.get("@level")).to eq "INFO" }

        it "sets [rtr] fields" do
          expect(parsed_results.get("rtr")["hostname"]).to eq "parser.64.78.234.207.xip.io"
          expect(parsed_results.get("rtr")["timestamp"]).to eq "15/07/2016:09:26:25 +0000"
          expect(parsed_results.get("rtr_time")).to be_nil
          expect(parsed_results.get("rtr")["verb"]).to eq "GET"
          expect(parsed_results.get("rtr")["path"]).to eq "/some/http"
          expect(parsed_results.get("rtr")["http_spec"]).to eq "HTTP/1.1"
          expect(parsed_results.get("rtr")["status"]).to eq 200
          expect(parsed_results.get("rtr")["request_bytes_received"]).to eq 0
          expect(parsed_results.get("rtr")["body_bytes_sent"]).to eq 1413
          expect(parsed_results.get("rtr")["referer"]).to eq "-"
          expect(parsed_results.get("rtr")["http_user_agent"]).to eq "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
          expect(parsed_results.get("rtr")["x_forwarded_for"]).to eq ["82.209.244.50", "192.168.111.21"]
          expect(parsed_results.get("rtr")["x_forwarded_proto"]).to eq "http"
          expect(parsed_results.get("rtr")["vcap_request_id"]).to eq "831e54f1-f09f-4971-6856-9fdd502d4ae3"
          # calculated values
          expect(parsed_results.get("rtr")["remote_addr"]).to eq "82.209.244.50"
          expect(parsed_results.get("rtr")["response_time_ms"]).to eq 5
        end

        it "sets geoip for [rtr][remote_addr]" do
          expect(parsed_results.get("geoip")).not_to be_nil
          expect(parsed_results.get("geoip")["ip"]).to eq "82.209.244.50"
        end

      end
    end

    context "RTR format (cf-release v250+)" do

      context "" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "type" => "RTR" },
            "@level" => "SOME LEVEL",
            # rtr format - quoted requestRemoteAddr and destIPandPort
            "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /some/http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" \"192.168.111.21:35826\" \"192.861.111.12:33456\" x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
        ) do

          # no parsing errors
          it { expect(parsed_results.get("tags")).to eq ["logmessage-rtr"] } # no fail tag

          # fields
          it { expect(parsed_results.get("@message")).to eq "200 GET /some/http (5 ms)" }
          it { expect(parsed_results.get("@level")).to eq "INFO" }

          it "sets [rtr] fields" do
            expect(parsed_results.get("rtr")["hostname"]).to eq "parser.64.78.234.207.xip.io"
            expect(parsed_results.get("rtr")["timestamp"]).to eq "15/07/2016:09:26:25 +0000"
            expect(parsed_results.get("rtr_time")).to be_nil
            expect(parsed_results.get("rtr")["verb"]).to eq "GET"
            expect(parsed_results.get("rtr")["path"]).to eq "/some/http"
            expect(parsed_results.get("rtr")["http_spec"]).to eq "HTTP/1.1"
            expect(parsed_results.get("rtr")["status"]).to eq 200
            expect(parsed_results.get("rtr")["request_bytes_received"]).to eq 0
            expect(parsed_results.get("rtr")["body_bytes_sent"]).to eq 1413
            expect(parsed_results.get("rtr")["referer"]).to eq "-"
            expect(parsed_results.get("rtr")["http_user_agent"]).to eq "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
            expect(parsed_results.get("rtr")["x_forwarded_for"]).to eq ["82.209.244.50", "192.168.111.21"]
            expect(parsed_results.get("rtr")["x_forwarded_proto"]).to eq "http"
            expect(parsed_results.get("rtr")["vcap_request_id"]).to eq "831e54f1-f09f-4971-6856-9fdd502d4ae3"
            # calculated values
            expect(parsed_results.get("rtr")["remote_addr"]).to eq "82.209.244.50"
            expect(parsed_results.get("rtr")["response_time_ms"]).to eq 5
          end

          it "sets geoip for [rtr][remote_addr]" do
            expect(parsed_results.get("geoip")).not_to be_nil
            expect(parsed_results.get("geoip")["ip"]).to eq "82.209.244.50"
          end

        end
      end
    end

    context "RTR format (cf-release v252+)" do

      context "" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "type" => "RTR" },
            "@level" => "SOME LEVEL",
            # rtr format - quoted requestRemoteAddr and destIPandPort
            "@message" => "parser.64.78.234.207.xip.io - [2017-03-16T13:28:25.166+0000] \"GET / HTTP/1.1\" 200 0 1677 \"-\" \"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.67 Safari/537.36\" \"10.2.9.104:60079\" \"10.2.32.71:61010\" x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"https\" vcap_request_id:\"f322dd76-aacf-422e-49fb-c73bc46ce45b\" response_time:0.001602684 app_id:\"27c02dec-80ce-4af6-94c5-2b51848edae9\" app_index:\"1\"\n"
        ) do

          # no parsing errors
          it { expect(parsed_results.get("tags")).to eq ["logmessage-rtr"] } # no fail tag

          # fields
          it { expect(parsed_results.get("@message")).to eq "200 GET / (1 ms)" }
          it { expect(parsed_results.get("@level")).to eq "INFO" }

          it "sets [rtr] fields" do
            expect(parsed_results.get("rtr")["hostname"]).to eq "parser.64.78.234.207.xip.io"
            expect(parsed_results.get("rtr")["timestamp"]).to eq "2017-03-16T13:28:25.166+0000"
            expect(parsed_results.get("rtr_time")).to be_nil
            expect(parsed_results.get("rtr")["verb"]).to eq "GET"
            expect(parsed_results.get("rtr")["path"]).to eq "/"
            expect(parsed_results.get("rtr")["http_spec"]).to eq "HTTP/1.1"
            expect(parsed_results.get("rtr")["status"]).to eq 200
            expect(parsed_results.get("rtr")["request_bytes_received"]).to eq 0
            expect(parsed_results.get("rtr")["body_bytes_sent"]).to eq 1677
            expect(parsed_results.get("rtr")["referer"]).to eq "-"
            expect(parsed_results.get("rtr")["http_user_agent"]).to eq "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.67 Safari/537.36"
            expect(parsed_results.get("rtr")["x_forwarded_for"]).to eq ["82.209.244.50", "192.168.111.21"]
            expect(parsed_results.get("rtr")["x_forwarded_proto"]).to eq "https"
            expect(parsed_results.get("rtr")["vcap_request_id"]).to eq "f322dd76-aacf-422e-49fb-c73bc46ce45b"
            expect(parsed_results.get("rtr")["src"]["host"]).to eq "10.2.9.104"
            expect(parsed_results.get("rtr")["src"]["port"]).to eq 60079
            expect(parsed_results.get("rtr")["dst"]["host"]).to eq "10.2.32.71"
            expect(parsed_results.get("rtr")["dst"]["port"]).to eq 61010
            expect(parsed_results.get("rtr")["app"]["id"]).to eq "27c02dec-80ce-4af6-94c5-2b51848edae9"
            expect(parsed_results.get("rtr")["app"]["index"]).to eq 1
            # calculated values
            expect(parsed_results.get("rtr")["remote_addr"]).to eq "82.209.244.50"
            expect(parsed_results.get("rtr")["response_time_ms"]).to eq 1
          end

          it "sets geoip for [rtr][remote_addr]" do
            expect(parsed_results.get("geoip")).not_to be_nil
            expect(parsed_results.get("geoip")["ip"]).to eq "82.209.244.50"
          end

        end
      end

      context "empty requestRemoteAddr and destIPandPort" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "type" => "RTR" },
            "@level" => "SOME LEVEL",
            # rtr format - quoted requestRemoteAddr and destIPandPort
            "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /some/http HTTP/1.1\" 200 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" \"-\" \"-\" x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
        ) do

          # no parsing errors
          it { expect(parsed_results.get("tags")).to eq ["logmessage-rtr"] } # no fail tag

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
        it { expect(parsed_results.get("tags")).to eq ["logmessage-rtr", "fail/cloudfoundry/app-rtr/grok"] }

        # fields
        it { expect(parsed_results.get("@message")).to eq "Some message of wrong format" } # keeps unchanged
        it { expect(parsed_results.get("@level")).to eq "SOME LEVEL" } # keeps unchanged

        it { expect(parsed_results.get("rtr")).to be_nil }
        it { expect(parsed_results.get("geoip")).to be_nil }

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
              " 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(parsed_results.get("@level")).to eq "INFO" }

      end
    end

    context "=400 (ERROR @level)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" " +
              "400" + # HTTP status =400
              " 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(parsed_results.get("@level")).to eq "ERROR" }

      end
    end

    context ">400 (ERROR @level)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "RTR" },
          "@level" => "SOME LEVEL",
          "@message" => "parser.64.78.234.207.xip.io - [15/07/2016:09:26:25 +0000] \"GET /http HTTP/1.1\" " +
              "401" + # HTTP status >400
              " 0 1413 \"-\" \"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\" 192.168.111.21:35826 x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(parsed_results.get("@level")).to eq "ERROR" }

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
              " x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it "removes quotes and whitespaces and split" do
          expect(parsed_results.get("rtr")["x_forwarded_for"]).to eq ["82.209.244.50", "192.168.111.21"]
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
              " x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(parsed_results.get("rtr")["x_forwarded_for"]).to eq [] } # empty

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
              " x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(parsed_results.get("rtr")["remote_addr"]).to eq "82.209.244.50" }

        it "sets geoip for [rtr][remote_addr]" do
          expect(parsed_results.get("geoip")).not_to be_nil
          expect(parsed_results.get("geoip")["ip"]).to eq "82.209.244.50"
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
              " x_forwarded_proto:\"http\" vcap_request_id:\"831e54f1-f09f-4971-6856-9fdd502d4ae3\" response_time:0.005328859 app_id:7ae227a6-6ad1-46d4-bfb9-6e60d7796bb5\n"
      ) do

        it { expect(parsed_results.get("rtr")["remote_addr"]).to eq "bad_format" }

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
        it { expect(parsed_results.get("tags")).to be_nil }

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
        it { expect(parsed_results.get("tags")).to be_nil }

      end
    end

  end

end
