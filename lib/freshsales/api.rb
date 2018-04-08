module Freshsales
  class API
    attr_accessor :freshsales_apikey, :freshsales_domain, :debug, :symbolize_keys, :logger, :adapter, :proxy

    def initialize(opts = {})
      @freshsales_apikey = opts.fetch(:freshsales_apikey, ENV["FRESHSALES_APIKEY"])
      @freshsales_domain = opts.fetch(:freshsales_domain, ENV["FRESHSALES_DOMAIN"])
      @symbolize_keys = false
      @debug = opts.fetch(:debug, false)
      @logger = ::Logger.new(STDOUT)
      @adapter = Faraday.default_adapter
      @proxy = nil

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
