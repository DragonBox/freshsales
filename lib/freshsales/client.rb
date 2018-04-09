module Freshsales
  class Client
    def initialize(config)
      @config = config
    end

    def httprequest(method_name, path, args = {})
      parse_response(freshsales_request(method_name, path, args))
    end

    def logger
      @config.logger
    end

    private

    def parse_response(response)
      parsed_response = nil

      if response.body && !response.body.empty?
        headers = response.headers
        body = response.body
        body = jsonify_body(body) unless @config.raw_data
        parsed_response = Response.new(headers: headers, body: body)
      end

      parsed_response
    end

    def jsonify_body(body)
      MultiJson.load(body, symbolize_keys: @config.symbolize_keys)
    rescue MultiJson::ParseError
      error_params = { title: "UNPARSEABLE_RESPONSE", status_code: 500 }
      error = FreshsalesError.new("Unparseable response: '#{body}'", error_params)
      raise error
    end

    def freshsales_domain
      "https://#{@config.freshsales_domain}.freshsales.io"
    end

    def freshsales_request(method, path, params: nil, headers: nil, body: nil)
      connection.send(method) do |request|
        request.headers['Content-Type'] = 'application/json'
        request.headers.update(headers) if headers
        request.params.update(params) if params
        if body
          body = MultiJson.dump(body) unless body.is_a? String
          request.body = body
        end
        request.url path
      end
    end

    def connection
      @connection ||=
        begin
          Faraday.new(freshsales_domain, proxy: @config.proxy, ssl: { version: "TLSv1_2" }) do |c|
            # c.request  :url_encoded
            c.response :raise_error
            c.use Faraday::Request::Authorization, 'Token', "token=#{@config.freshsales_apikey}"
            if @config.debug
              c.response :logger, @config.logger, bodies: true do |logger|
                logger.filter(/(Token token=)(\w+)/, '\1[HIDDEN]')
              end
            end
            c.adapter @config.faraday_adapter
          end
        end
    end
  end
end
