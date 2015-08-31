# -*- coding: utf-8 -*-
require 'spec_helper'
require 'json_and_string_parameter_filter'

RSpec.describe JsonAndStringParameterFilter do
  let!(:string_filters) { [:Email, :last_name, :password] }
  let!(:json_key_filters) { [:password] }
  let!(:value_filters) { [Proc.new { |value| value =~ /^[^@]+@[^.]+\..+/ }] }

  let!(:filter) {
    JsonAndStringParameterFilter.new(
      string_filters, json_key_filters, value_filters)
  }

  let!(:params_1) {
    { "utf8" => "✓",
      "username" => "admin",
      "password" => "Pa$$word",
      "provider" => "identity",
      "email_address" => "admin@example.com",
      "other" => {
        "something" => "test@an.example.com"
      }
    }
  }

  let!(:params_2) { {
      "{\"email\":null,\"username\":\"student16\",\"password\":\"password\",\"other\":{\"me\":\"me@example.com\"}}" => nil
  } }

  let!(:params_3) { {
    "utf8" => "✓",
    "contact_info" => {
      "type" => "EmailAddress",
      "value" => "test@example.org" },
    "commit"=>"Add Email address"
  } }

  def do_filter(params)
    filtered_params = {}
    params.each do |key, value|
      key = key.dup
      value = value.dup if value.duplicable?
      filter.run(key, value)
      filtered_params[key] = value
    end
    filtered_params
  end

  it 'filters string parameters' do
    filtered_params = do_filter(params_1)

    expect(filtered_params).to eq({
      "utf8" => "✓",
      "username" => "admin",
      "password" => "[FILTERED]",
      "provider" => "identity",
      "email_address" => "[FILTERED]",
      "other" => {
        "something" => "[FILTERED]"
      }
    })
  end

  it 'filters json parameters' do
    filtered_params = do_filter(params_2)

    expect(filtered_params).to eq({
      "{\"email\":null,\"username\":\"student16\",\"password\":\"[FILTERED]\",\"other\":{\"me\":\"[FILTERED]\"}}" => nil
    })
  end

  it 'filters by value' do
    filtered_params = do_filter(params_3)

    expect(filtered_params).to eq({
      "utf8" => "✓",
      "contact_info" => {
        "type" => "EmailAddress",
        "value" => "[FILTERED]" },
      "commit"=>"Add Email address"
    })
  end
end
