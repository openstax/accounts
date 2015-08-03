# -*- coding: utf-8 -*-
require 'spec_helper'
require 'json_and_string_parameter_filter'

RSpec.describe JsonAndStringParameterFilter do
  let!(:string_filters) { [:Email, :last_name, :password] }
  let!(:json_key_filters) { [:password] }

  let!(:filter) {
    JsonAndStringParameterFilter.new(
      string_filters, json_key_filters)
  }

  let!(:params_1) {
    { "utf8" => "✓",
      "username" => "admin",
      "password" => "Pa$$word",
      "provider" => "identity",
      "email_address" => "admin@example.com" }
  }

  let!(:params_2) { {
      "{\"email\":null,\"username\":\"student16\",\"password\":\"password\"}" => nil
  } }

  it 'filters string parameters' do
    filtered_params = {}
    params_1.each do |key, value|
      key = key.dup
      value = value.dup if value.duplicable?
      filter.run(key, value)
      filtered_params[key] = value
    end

    expect(filtered_params).to eq({
      "utf8" => "✓",
      "username" => "admin",
      "password" => "[FILTERED]",
      "provider" => "identity",
      "email_address" => "[FILTERED]"
    })
  end

  it 'filters json parameters' do
    filtered_params = {}
    params_2.each do |key, value|
      key = key.dup
      value = value.dup if value.duplicable?
      filter.run(key, value)
      filtered_params[key] = value
    end

    expect(filtered_params).to eq({
      "{\"email\":null,\"username\":\"student16\",\"password\":\"[FILTERED]\"}" => nil
    })
  end
end
