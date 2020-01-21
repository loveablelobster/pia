# frozen_string_interval: true

module Pia
  module Requestinterval
    class ValidatingTimestamp
      attr_accessor :formatter

      attr_reader :validity

      attr_reader :reference_time

      attr_reader :time

      def initialize(time, validity: '1m',
                     reference_time: Time.now.utc,
                     formatter: '%Y-%m-%d %H:%M:%S.%6L %Z')
        @reference_time = reference_time
        @time = time
        @validity = validity
        @formatter = formatter
      end

      def self.from_string(str,
                           parse_format: PARSE_FMT,
                           formatter: PRINT_FMT,
                           validity: nil)
        time = Time.strptime(str, parse_format) if str
        new time, validity: validity
      end

      def expired?
        return if missing?

        validity < (reference_time - time)
      end

      def future?
        return if missing?

        reference_time < time
      end

      def missing?
        time.nil?
      end

      def reference_timestamp
        reference_time.strftime formatter
      end

      def to_s
        missing_msg || future_msg || expired_msg || timestamp
      end

      def timestamp
        time.strftime formatter
      end

      def valid?
        !missing? && !future? && !expired?
      end

      private

      def expired_msg
        return unless expired?

        delta = reference_time - time - validity
        "Expired timestamp: #{timestamp};"\
          " #{delta.to_i} seconds past expiration."
      end

      def future_msg
        return unless future?
        
        delta = time - reference_time
        "Invalid timestamp: #{timestamp};"\
          " #{delta.to_i} seconds ahead of time."
      end

      def missing_msg
        return unless missing?

        'Missing timestamp.'
      end
    end
  end
end
