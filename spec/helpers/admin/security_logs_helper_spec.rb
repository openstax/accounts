require 'rails_helper'

describe Admin::SecurityLogsHelper, type: :helper do
  describe "#security_log_filter_path" do
    def query_from(path)
      Rack::Utils.parse_nested_query(URI.parse(path).query).dig('search', 'query')
    end

    it "removes an embedded double quote so it can't end the quoted term early" do
      path = helper.security_log_filter_path('user', 'inject" other_keyword:"x')

      expect(query_from(path)).to eq 'user:"inject other_keyword:x"'
    end

    it "keeps a comma and spaces in the value intact" do
      path = helper.security_log_filter_path('user', 'a value, with spaces')

      expect(query_from(path)).to eq 'user:"a value, with spaces"'
    end

    it "handles a value containing a quote, a comma, and a space together" do
      path = helper.security_log_filter_path('user', 'quo"te, with space')

      expect(query_from(path)).to eq 'user:"quote, with space"'
    end

    it "passes safe values (an integer id) through unchanged" do
      path = helper.security_log_filter_path('user_id', 42)

      expect(query_from(path)).to eq 'user_id:"42"'
    end
  end

  describe "#security_log_active_filters" do
    it "returns nothing when the query is blank" do
      expect(helper.security_log_active_filters(nil)).to eq []
      expect(helper.security_log_active_filters('')).to eq []
    end

    it "returns a readable label and a remove path for each term" do
      filters = helper.security_log_active_filters('ip:"10.0.0.1" type:"sign_in_failed"')

      expect(filters.map { |f| f[:label] }).to match_array ['IP 10.0.0.1', 'Type Sign in failed']
    end

    it "builds a remove path that drops only the matching term" do
      filters = helper.security_log_active_filters('ip:"10.0.0.1" type:"sign_in_failed"')
      ip_filter = filters.detect { |f| f[:label] == 'IP 10.0.0.1' }

      remaining_query = Rack::Utils.parse_nested_query(URI.parse(ip_filter[:remove_path]).query)
                                    .dig('search', 'query')

      expect(remaining_query).to eq 'type:"sign_in_failed"'
    end
  end
end
