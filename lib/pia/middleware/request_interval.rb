# frozen_string_literal: true

module Pia
  module Middleware
    # Middleware that validates timestamps sent in a POST request body by a given
    # expiration interval.
    #
    # FIXME: This comment below...
    # The message body must be multipart in the format <tt>%Y-%m-%d %H:%M:%S.%L</tt>
    # and contained in a +timestamp+ property of the JSON (for details on the JSON
    # structure see FileAuth).
    class RequestInterval
      # Returns a new instance.
      #
      # ===== Options
      #
      # * <tt>:timeout</tt> - Amount of time when a request expires, a String.
      # * <tt>:logger</tt> - Logger instance to use for logging.
      #
      # The <tt>:timeout</tt> option is passed as a String with hours (+h+),
      # minutes (+m+), and seconds (+s+).
      #
      # ===== Examples
      #
      #   '3h'         # => 10800 seconds
      #   '30m'        # => 1800 seconds
      #   '15s'        # => 15 seconds
      #   '1h 15m'     # => 4500 seconds
      #   '1m 30s'     # => 90 seconds
      #   '1h 5s'      # => 3605 seconds
      #   '1h 20m 45s' # => 4845 seconds
      #
      def initialize(app, **opts)
        @app = app
        @allowed_delta = Timespan.in_seconds opts.fetch(:timeout, '1h')
        @logger = opts[:logger]
      end

      def call(env)
        req = Rack::Request.new env
        timestamp = parse_timestamp req.params
        if valid? timestamp
          @app.call env
        else
          raise TimestampError, timestamp: timestamp, middleware: self
        end
      rescue UploadError => e
        @logger&.warn e.message
        e.response
      end

      # FIXME
      def inspect
        "Return something meaningful here"
      end

      private

      # Returns +true+ if +timestamp+ is valid. +false+ if is expired or in the
      # future.
      def valid?(timestamp)
        now = Time.now.utc
        return false if timestamp > now

        actual_delta = now - timestamp
        @allowed_delta >= actual_delta
      end

      # Parses the timestring from +params+. Returns a Time object for the
      # timestamp.
      def parse_timestamp(params)
        timestamp = params.fetch('timestamp')
        raise TimestampError, middleware: self unless timestamp
        timestamp += ' UTC'
        Time.strptime(timestamp, '%Y-%m-%d %H:%M:%S.%L %Z')
      rescue KeyError => e
        raise TimestampError, middleware: self
      end
    end
  end
end
