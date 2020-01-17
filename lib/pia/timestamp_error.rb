# frozen_string_literal: true

module Pia
  # Class for exceptions that are raised when a timestamp is invalid or missing.
  class TimestampError < UploadError
    # Timestamp that failed validation.
    attr_reader :timestamp

    # Returns a new instance.
    def initialize(msg = nil, middleware: nil, timestamp: nil)
      @middleware = middleware
      @timestamp = timestamp
      msg ||= default_msg
      super msg
    end

    private

    def default_msg
      add_mw_to ts_msg || 'Attempted file upload without a timestamp.'
    end

    def ts_msg
      return unless timestamp

      'Attempted file upload with an invalid timestamp:'\
        " #{timestamp.strftime('%Y-%m-%d %H:%M:%S.%6L')}."
    end
  end
end
