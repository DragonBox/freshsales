# frozen_string_literal: true

module Freshsales
  class RequestBuilder
    def initialize(client)
      @client = client
      @httpmethods = %i[get put post delete]

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

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    private

    def path
      "/api/#{@path_parts.join('/')}"
    end
  end
end
