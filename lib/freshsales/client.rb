# frozen_string_literal: true

module Freshsales
  class Client
    def initialize(config)
      @config = config
    end

    def httprequest(method_name, path, args = {})
      parse_response(freshsales_request(method_name, path, **args))
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

    def jsonify_body(body, ignore_parsing_errors: false)
      MultiJson.load(body, symbolize_keys: @config.symbolize_keys)
    rescue MultiJson::ParseError => e
      return if ignore_parsing_errors
      error_params = { detail: e.message, status_code: 500, raw_body: body }
      error = FreshsalesError.new("Unparseable response", error_params)
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
    rescue StandardError => e
      handle_request_error(e)
    end

    def handle_request_error(error)
      error_params = {}
      if error.is_a?(Faraday::ClientError) && error.response
        error_params[:status_code] = error.response[:status]
        error_params[:raw_body] = error.response[:body]

        parsed_response = jsonify_body(error.response[:body], ignore_parsing_errors: true)

        if parsed_response
          error_params[:body] = parsed_response

          code_key = @config.symbolize_keys ? :code : "code"
          message_key = @config.symbolize_keys ? :message : "message"

          error_params[:code] = parsed_response[code_key] if parsed_response[code_key]
          error_params[:detail] = parsed_response[message_key] if parsed_response[message_key]
        end
      end
      message = error_params[:detail] || error.message
      error_to_raise = FreshsalesError.new(message, error_params)

      raise error_to_raise
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
