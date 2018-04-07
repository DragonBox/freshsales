require 'logger'
require 'uri'
require 'cgi'
require 'multi_json'
require 'pry'
require 'faraday'

# TODO
# clean pagination API
# handle errors (Faraday::Error::ClientError)
# configuration options

module Freshsales
	VERSION = "0.0.1"

	class API
		attr_accessor :freshsales_token, :freshsales_domain, :debug, :symbolize_keys, :logger, :adapter, :proxy

		def initialize(opts = {})
			@freshsales_token  = opts.fetch(:freshsales_token, ENV["FRESHSALES_TOKEN"])
			@freshsales_domain = opts.fetch(:freshsales_domain, ENV["FRESHSALES_DOMAIN"])
			@symbolize_keys = false
			@debug = opts.fetch(:debug, false)
			@logger = ::Logger.new(STDOUT)
			@adapter = Faraday.default_adapter
			@proxy = nil

			@client = Client.new(self)
		end

		def method_missing(method, *args)
			request = RequestBuilder.new(@client)
			request.send(method, *args)
			request
		end

		def respond_to_missing?(method_name, include_private = false)
			true
		end
	end

	class FreshsalesError < StandardError;
		attr_reader :params

		def initialize(message = "", params = {})
			@params = params
			super(message)
		end

		def to_s
			super + " " + params.to_s
		end
	end

	class RequestBuilder
		def initialize(client)
			@client = client
			@httpmethods = [:get, :put, :post, :delete]

			@path_parts = []
		end

		def get_all_pages(*args)
			Cursor.new(@client, path, :page, @path_parts[0], *args)
		end

		def get_all(*args)
			Cursor.new(@client, path, :elt, @path_parts[0], *args)
		end

		def method_missing(method, *args)
			if @httpmethods.include? method
				@client.httprequest(method.to_s, path, *args)
			else
				@path_parts << method.to_s
				args.each do |arg|
					@path_parts << arg
				end
				self
			end
		end
		def respond_to_missing?(method_name, include_private = false)
			true
		end

		private

		def path
			"/api/#{@path_parts.join('/')}"
		end
	end

	class Response
		attr_accessor :headers, :body

		def initialize(headers: {}, body: {})
			@headers = headers
			@body = body
		end
	end


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
				begin
					headers = response.headers
					body = MultiJson.load(response.body, symbolize_keys: @config.symbolize_keys)
					parsed_response = Response.new(headers: headers, body: body)
				rescue MultiJson::ParseError
					error_params = { title: "UNPARSEABLE_RESPONSE", status_code: 500 }
					error = FreshsalesError.new("Unparseable response: '#{response.body}'", error_params)
					raise error
				end
			end

			parsed_response
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
					unless body.is_a? String
						body = MultiJson.dump(body)
					end
					request.body = body
				end
				request.url path
			end
		end

		def connection
			@connection ||=
				begin
					Faraday.new(freshsales_domain, proxy: @config.proxy, ssl: { version: "TLSv1_2" }) do |c|
						#c.request  :url_encoded
						c.response :raise_error
						c.use Faraday::Request::Authorization, 'Token', "token=#{@config.freshsales_token}"
						if @config.debug
							c.response :logger, @config.logger, bodies: true do |logger|
								logger.filter(/(Token token=)(\w+)/, '\1[HIDDEN]')
							end
						end
						c.adapter @config.adapter
					end
				end
		end
	end

	class Cursor
		include Enumerable

		def initialize(client, path, type, collection_name, args)
			@client     = client
			@path       = path
			@type       = type
			@collection_name = collection_name
			@args     	= args

			@collection = []
			@page       = params.fetch(:page, 0)
		end

		def params
			(@args[:params] || {})
		end

		def each(start = 0)
			return to_enum(:each, start) unless block_given?

			Array(@collection[start..-1]).each do |element|
					yield(element)
			end

			unless last?
				start = [@collection.size, start].max

				fetch_next_page

				each(start, &Proc.new)
			end
		end

		private

		def client
			@client
		end

		def logger
			@client.logger
		end

		MAX = 100000 # FIXME get rid off or configure

		def fetch_next_page
			nextpage = @page + 1
			@args[:params] = params.merge(page: nextpage)
			response = client.httprequest(:get, @path, @args)
			j = response.body

			# might have been symbolized
			if (j.is_a? Hash)
				meta = (j['meta'] || j[:meta])
				total_pages = (meta['total_pages'] || meta[:total_pages])
				last = nextpage == total_pages
				logger.debug "Found #{nextpage}/#{total_pages} #{@type} #{@collection_name} (#{j.keys.map{|k| [k, j[k].count]}.join(",")}) last? #{last}"
				data =
					case @type
					when :page
						[j]
					when :elt
						j[@collection_name]
					end
			elsif (j.is_a? Array)
				# most probably searching
				last = true
				logger.debug "Found #{j.count} elements #{@type} #{@collection_name}"

				data = j
			else
				raise "Unexpected data type received #{j.class}"
			end

			@last_response        = last
			@collection           += data
			@page                 = nextpage
		end

		def last?
			@last_response || @collection.size >= MAX
		end		
	end
end
