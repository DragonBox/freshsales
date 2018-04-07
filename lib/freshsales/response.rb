module Freshsales
  class Response
    attr_accessor :headers, :body

    def initialize(headers: {}, body: {})
      @headers = headers
      @body = body
    end
  end
end
