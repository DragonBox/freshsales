# frozen_string_literal: true

module Freshsales
  class Cursor
    include Enumerable

    def initialize(client, path, type, collection_name, args = {})
      @client = client
      @path       = path
      @type       = type
      @collection_name = collection_name
      @args	= args

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

      return if last?

      start = [@collection.size, start].max

      fetch_next_page

      each(start, &Proc.new)
    end

    private

    attr_reader :client

    def logger
      @client.logger
    end

    def fetch_next_page
      nextpage = @page + 1
      @args[:params] = params.merge(page: nextpage)
      response = client.httprequest(:get, @path, @args)
      j = response.body

      # might have been symbolized
      if j.is_a? Hash
        meta = (j['meta'] || j[:meta])
        total_pages = (meta['total_pages'] || meta[:total_pages])
        last = nextpage == total_pages
        logger.debug "Found #{nextpage}/#{total_pages} #{@type} #{@collection_name} (#{j.keys.map { |k| [k, j[k].count] }.join(',')}) last? #{last}"
        data =
          case @type
          when :page
            [j]
          when :elt
            j[@collection_name]
          end
      elsif j.is_a? Array
        # most probably searching
        last = true
        logger.debug "Found #{j.count} elements #{@type} #{@collection_name}"

        data = j
      elsif j.is_a? String
        raise "Unexpected data type received #{j.class}. Are you combining pagination with raw_data? Unsupported for now"
      else
        raise "Unexpected data type received #{j.class}."
      end

      @last_response = last
      @collection += data
      @page = nextpage
    end

    def last?
      @last_response
    end
  end
end
