# frozen_string_literal: true

require_relative 'requestinterval/duration'
require_relative 'requestinterval/validating_timestamp'

module Pia
  # A Roda plugin to validate timestamps sent as request parameters.
  #
  # Timestamps must be in the format matched by PARSE_FMT constant. If no
  # timezone is specified, UTC will be assumed.
  #
  # They must be stored in the params hash under the key specified by the
  # <tt>:timestamp_key</tt> option (<em>default:</em> <tt>'timestamp'</tt>).
  #
  # If a timestamp is not valid (missing, expired, or in the future), the
  # request will be haltet, and a warning will be logged if the
  # <tt>:common_logger</tt> option is set for the application.
  module Requestinterval
    PARSE_FMT = '%Y-%m-%d %H:%M:%S.%L %Z'
    PRINT_FMT = '%Y-%m-%d %H:%M:%S.%6L %Z'

    def self.configure(app, **opts)
      # FIXME: move the Duration.in_seconds parsing to the settings facility one
      # we have one.
      duration = Duration.in_seconds(opts[:request_exp_time]) || 30
      app.opts[:request_exp_time] ||= duration
      app.opts[:timestamp_key] ||= opts.fetch :timestamp_key, 'timestamp'
      app.opts[:time_parse_fmt] ||= opts.fetch :time_parse_fmt, PARSE_FMT
      app.opts[:time_print_fmt] ||= opts.fetch :time_print_fmt, PRINT_FMT
    end

    # Registers the Logger plugin with +app+.
    def self.load_dependencies(app, **_opts)
      app.plugin Logger
    end

    # Methods included in the request.
    module RequestMethods
      # Returns a string for the timestamp sent in the request parameters. If no
      # timezone is specified, UTC will be assumed.
      #
      # Returns +nil+ if there is no timestamp.
      def timestamp
        ts = params[roda_class.opts[:timestamp_key]]
        return if ts.nil? || ts.empty?

        return ts if /[A-Z]{3}$/.match? ts

        ts + ' UTC'
      end

      # Verifies that the timestamp passes in the request parameters is present
      # and not expired or invalid.
      #
      # If the timestamp is invalid, the request will be haltet, and a warning
      # will be logged if the <tt>:common_logger</tt> option is set for the
      # application.
      def validate_timestamp
        ts = ValidatingTimestamp
             .from_string(timestamp,
                          parse_format: roda_class.opts[:time_parse_fmt],
                          validity: expiration_time)
        return self if ts.valid?

        roda_class.opts[:common_logger]&.warn "Request aborted. #{ts}"
        halt [111,
              { 'Content-Type' => 'text/html' },
              { message: 'Bad request. Ignored.' }.to_json]
      end

      private

      def expiration_time
        roda_class.opts[:request_exp_time]
      end
    end
  end
end
