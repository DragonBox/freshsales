# frozen_string_literal: true

module Freshsales
  class API
    attr_accessor :freshsales_apikey, :freshsales_domain, :debug, :symbolize_keys, :logger, :faraday_adapter, :proxy, :raw_data

    def initialize(opts = {})
      @freshsales_apikey = opts.fetch(:freshsales_apikey, ENV["FRESHSALES_APIKEY"])
      @freshsales_domain = opts.fetch(:freshsales_domain, ENV["FRESHSALES_DOMAIN"])
      @raw_data = opts.fetch(:raw_data, false)
      @symbolize_keys = opts.fetch(:symbolize_keys, false)
      @debug = opts.fetch(:debug, false)
      @logger = opts.fetch(:logger, ::Logger.new($stdout))
      @faraday_adapter = opts.fetch(:faraday_adapter, Faraday.default_adapter)
      @proxy = opts.fetch(:proxy, ENV["FRESHSALES_PROXY"])

      @client = Client.new(self)
    end

    def method_missing(method, *args)
      request = RequestBuilder.new(@client)
      request.send(method, *args)
      request
    end

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end
  end
end
