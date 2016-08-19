# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

describe "teardown.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/teardown.conf")}
      }
    CONFIG
  end

  describe "sets @level based on [syslog_severity_code]" do

    context "([syslog_severity_code] = 2)" do
      when_parsing_log( "syslog_severity_code" => 2 ) do
        it { expect(subject["@level]"]).to eq "ERROR" }
      end
    end

    context "([syslog_severity_code] = 3)" do
      when_parsing_log( "syslog_severity_code" => 3 ) do
        it { expect(subject["@level"]).to eq "ERROR" }
      end
    end

    context "([syslog_severity_code] = 4)" do
      when_parsing_log( "syslog_severity_code" => 4 ) do
        it { expect(subject["@level"]).to eq "WARN" }
      end
    end

    context "([syslog_severity_code] = 5)" do
      when_parsing_log( "syslog_severity_code" => 5 ) do
        it { expect(subject["@level"]).to eq "WARN" }
      end
    end

    context "([syslog_severity_code] = 6)" do
      when_parsing_log( "syslog_severity_code" => 6 ) do
        it { expect(subject["@level"]).to eq "INFO" }
      end
    end

    context "([syslog_severity_code] = 7)" do
      when_parsing_log( "syslog_severity_code" => 7 ) do
        it { expect(subject["@level"]).to eq "DEBUG" }
      end
    end

    context "([syslog_severity_code] = 8)" do
      when_parsing_log( "syslog_severity_code" => 8 ) do
        it { expect(subject["@level"]).to be_nil }
      end
    end

    context "(no [syslog_severity_code])" do
      when_parsing_log( "some_field" => "some_value" ) do
        it { expect(subject["@level"]).to be_nil }
      end
    end

  end

  describe "sets [@source][name]" do

    context "when [@source]* fields are set" do
      when_parsing_log(
          "@source" => {"job" => "Abc", "instance" => "123"}
      ) do
        it { expect(subject["@source"]["name"]).to eq "Abc/123" }
      end
    end

    context "when [@source][job] is missing" do
      when_parsing_log(
          "@source" => {"instance" => "123"}
      ) do
        it { expect(subject["@source"]["name"]).to be_nil }
      end
    end

    context "when [@source][instance] is missing" do
      when_parsing_log(
          "@source" => {"job" => "Abc"}
      ) do
        it { expect(subject["@source"]["name"]).to be_nil }
      end
    end

    context "when [@source]* fields are missing" do
      when_parsing_log(
          "@source" => {"some useless field" => "Abc"}
      ) do
        it { expect(subject["@source"]["name"]).to be_nil }
      end
    end

  end

  describe "converts [@source][instance]" do

    when_parsing_log(
        "@source" => {"instance" => "123"}
    ) do
      it { expect(subject["@source"]["instance"]).to eq 123 }
    end

  end

  describe "converts [@source][instance]" do

    when_parsing_log(
        "@source" => {"instance" => "123"}
    ) do
      it { expect(subject["@source"]["instance"]).to eq 123 }
    end

  end

  describe "parses [host]" do

    context "when [@source][host] is set" do
      when_parsing_log(
          "host" => "1.2.3.4",
          "@source" => {"host" => "5.6.7.8"}
      ) do
        it { expect(subject["@source"]["host"]).to eq "5.6.7.8" }
        it { expect(subject["host"]).to be_nil }
      end
    end

    context "when [@source][host] is NOT set" do
      when_parsing_log(
          "host" => "1.2.3.4"
      ) do
        it { expect(subject["@source"]["host"]).to eq "1.2.3.4" }
        it { expect(subject["host"]).to be_nil }
      end
    end

  end

  describe "renames [parsed_json_field]" do

    describe "when [parsed_json_field] and [parsed_json_field_name] are set" do
      when_parsing_log(
          "parsed_json_field" => "dummy value",
          "parsed_json_field_name" => "Abc-defg.hI?jk#lm NOPQ"
      ) do
        # [parsed_json_field] renamed
        it { expect(subject["parsed_json_field"]).to be_nil }
        it { expect(subject["parsed_json_field_name"]).to be_nil }
        it { expect(subject["abc_defg_hi_jk_lm_nopq"]).to eq "dummy value" } # renamed
      end
    end

    context "when [parsed_json_field] is NOT set" do
      when_parsing_log(
          "parsed_json_field_name" => "Abc-defg.hI?jk#lm NOPQ"
      ) do
        # nothing is set
        it { expect(subject["parsed_json_field"]).to be_nil }
        it { expect(subject["parsed_json_field_name"]).to be_nil }
        it { expect(subject["abc_defg_hi_jk_lm_nopq"]).to be_nil }
      end
    end

    context "when [parsed_json_field_name] is NOT set" do
      when_parsing_log(
          "parsed_json_field" => "dummy value"
      ) do
        # keep [parsed_json_field]
        it { expect(subject["parsed_json_field"]).to eq "dummy value" }
        it { expect(subject["parsed_json_field_name"]).to be_nil }
      end
    end

  end

  describe "cleanup" do

    when_parsing_log(
      "syslog_pri" => "abc",
      "syslog_facility" => "def",
      "syslog_facility_code" => "ghi",
      "syslog_message" => "jkl",
      "syslog_severity" => "mno",
      "syslog_severity_code" => "pqr",
      "syslog_program" => "stu",
      "syslog_timestamp" => "vw",
      "syslog_hostname" => "xy",
      "syslog_pid" => "z",
      "@level" => "lowercase value",
      "@version" => "some version",
      "host" => "1.2.3.4",
      "_logstash_input" => "abc"
    ) do

      it "removes syslog_ fields" do
        expect(subject["syslog_pri"]).to be_nil
        expect(subject["syslog_facility"]).to be_nil
        expect(subject["syslog_facility_code"]).to be_nil
        expect(subject["syslog_message"]).to be_nil
        expect(subject["syslog_severity"]).to be_nil
        expect(subject["syslog_severity_code"]).to be_nil
        expect(subject["syslog_program"]).to be_nil
        expect(subject["syslog_timestamp"]).to be_nil
        expect(subject["syslog_hostname"]).to be_nil
        expect(subject["syslog_pid"]).to be_nil
      end

      it { expect(subject["@level"]).to eq "LOWERCASE VALUE" }

      it { expect(subject["@version"]).to be_nil }
      it { expect(subject["host"]).to be_nil }
      it { expect(subject["_logstash_input"]).to be_nil }

    end

  end

end
