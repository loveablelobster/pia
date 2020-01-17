# frozen_string_literal: true

module Pia
  # Default JSON for a bad HTTP request.
  BAD_REQUEST = { message: 'Bad request. Ignored.' }.to_json

  # Class for exceptions that are raised when a POST request to upload a file
  # fails.
  # This class is intended to be subclassed. The #body and #status returb values
  # are to be defined in the subclassed.
  class UploadError < StandardError
    # Hash with HTTP headers for #response.
    attr_reader :header

    # Middleware that raised the exception.
    attr_reader :middleware

    # Integer with HTTP status for #response.
    attr_reader :status

    # Returns a new instance.
    def initialize(msg = nil, middleware: nil)
      @header = {}
      @middleware ||= middleware
      @status = 111
      msg ||= default_message
      super msg
    end

    # Returns JSON for a response body that is used by #response.
    def body
      BAD_REQUEST
    end

    # Returns an Array with #status, #header, and #body.
    #
    # This can be returned when the error is rescued in the +call+ method of a
    # middleware handling the request. The +rescue+ clause can then terminate
    # with this response.
    def response
      [status, header, body]
    end

    private

    def default_message
      add_mw_to 'Upload failed.'
    end

    def add_mw_to(msg)
      return msg unless middleware

      msg += " Stopped in #{middleware.inspect}."
    end
  end
end
