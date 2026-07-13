# frozen_string_literal: true

module Bugsage
  class HttpResponseError < StandardError
    attr_reader :status, :response_body, :location

    def initialize(status:, message:, response_body: nil, location: nil)
      @status = status
      @response_body = response_body
      @location = location
      super(message)
    end
  end
end
