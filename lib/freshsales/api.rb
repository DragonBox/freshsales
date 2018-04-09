module Freshsales
  class API
    attr_accessor :freshsales_apikey, :freshsales_domain, :debug, :symbolize_keys, :logger, :faraday_adapter, :proxy

    def initialize(opts = {})
      @freshsales_apikey = opts.fetch(:freshsales_apikey, ENV["FRESHSALES_APIKEY"])
      @freshsales_domain = opts.fetch(:freshsales_domain, ENV["FRESHSALES_DOMAIN"])
      @symbolize_keys = opts.fetch(:symbolize_keys, false)
      @debug = opts.fetch(:debug, false)
      @logger = opts.fetch(:logger, ::Logger.new(STDOUT))
      @faraday_adapter = opts.fetch(:faraday_adapter, Faraday.default_adapter)
      @proxy = opts.fetch(:proxy, ENV["FRESHSALES_PROXY"])

      @client = Client.new(self)
    end

    # rubocop:disable Style/MethodMissing
    def method_missing(method, *args)
      request = RequestBuilder.new(@client)
      request.send(method, *args)
      request
    end
    # rubocop:enable Style/MethodMissing

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end
  end
end
