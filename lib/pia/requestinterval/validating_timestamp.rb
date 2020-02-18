# frozen_string_literal: true

module Pia
  module Requestinterval
    # ValidatingTimestamp objects wrap a time and compare it to a reference
    # time.
    class ValidatingTimestamp
      # Format string for the timestamp when converted to String.
      attr_accessor :formatter

      # Duration in seconds that may elapse from #reference_time until #time is
      # considered expired.
      attr_reader :validity

      # Time object that serves a point of reference for comparison with #time.
      attr_reader :reference_time

      # Time object.
      attr_reader :time

      # Returns a new instance for +time+ (a Time object).
      #
      # ===== Options
      #
      # * <tt>:validity</tt> - Integer, duration in seconds during which a
      #   timestamp is valid.
      # * <tt>:reference_time</tt> - Time, the time that is the point of
      #   reference for expiration (<em>default:</tt> the current UTC time).
      # * <tt>:formatter</tt> - String, the format string used by Time.strftime
      #   create a formatted timestamp.
      def initialize(time, validity: 60,
                     reference_time: Time.now.utc,
                     formatter: '%Y-%m-%d %H:%M:%S.%6L %Z')
        @reference_time = reference_time
        @time = time
        @validity = validity
        @formatter = formatter
      end

      # Creates a new instance from +str+ (a String).
      #
      # ===== Options
      #
      # * <tt>:parse_format</tt> - String, the format of the timestamp used by
      #   Time.strptime.
      # * <tt>:validity</tt> - Integer, duration in seconds during which a
      #   timestamp is valid.
      def self.from_string(str,
                           parse_format: PARSE_FMT,
                           validity: nil)
        time = Time.strptime(str, parse_format) if str
        new time, validity: validity
      end

      # Returns +true+ if the delta between #time and #reference_time exceeds
      # the allowed validity span.
      def expired?
        return if missing?

        validity < (reference_time - time)
      end

      # Returns +true+ if the #time attribute of +self+ is a a time in the
      # future relative to the #reference_time.
      def future?
        return if missing?

        reference_time < time
      end

      # Returns +true+ if +self+ does not contain a timestamp. +false+
      # otherwise.
      def missing?
        time.nil?
      end

      # Returns a timestamp (String representation) for the #reference_time.
      def reference_timestamp
        reference_time.strftime formatter
      end

      # Returns a String representation of self, including reasons for
      # invalidity, if any.
      def to_s
        missing_msg || future_msg || expired_msg || timestamp
      end

      # Returns a timestamp as a String for +self+.
      def timestamp
        time.strftime formatter
      end

      # Returns +true+ if +self+ is a valid timestamp.
      def valid?
        !missing? && !future? && !expired?
      end

      private

      # Returns message (String) when the timestamp is expired.
      def expired_msg
        return unless expired?

        delta = reference_time - time - validity
        "Expired timestamp: #{timestamp};"\
          " #{delta.to_i} seconds past expiration."
      end

      # Returns message (String) when the timestamp is in the future.
      def future_msg
        return unless future?

        delta = time - reference_time
        "Invalid timestamp: #{timestamp};"\
          " #{delta.to_i} seconds ahead of time."
      end

      # Returns message (String) when the timestamp is missing.
      def missing_msg
        return unless missing?

        'Missing timestamp.'
      end
    end
  end
end
