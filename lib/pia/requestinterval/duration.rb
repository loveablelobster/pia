# frozen_string_literal: true

module Pia
  # Timespans are initialized with a String that specifies a duration in simple
  # a simple notation using integers and the tokens +h+ (hours), +m+ (minutes),
  # and +s+ (seconds) and can calculate the duration in seconds.
  #
  # ===== Examples
  #
  #   Duration.in_seconds('3h')         # => 10800 seconds
  #   Duration.in_seconds('30m')        # => 1800 seconds
  #   Duration.in_seconds('15s')        # => 15 seconds
  #   Duration.in_seconds('1h 15m')     # => 4500 seconds
  #   Duration.in_seconds('1m 30s')     # => 90 seconds
  #   Duration.in_seconds('1h 5s')      # => 3605 seconds
  #   Duration.in_seconds('1h 20m 45s') # => 4845 seconds
  #
  class Duration
    # Regular expression for String parsing.
    PATTERN = /^(?<h>\d+\s*h)?\s*(?<m>\d+\s*m)?\s*(?<s>\d+\s*s)?$/.freeze

    # Methods available for extraction of temporal constituents of +self+.
    METHODS = %i[hours minutes seconds].freeze

    # :arg: interval_string
    #
    # Creates a new instacne for <tt>interval_string</tt>.
    #
    # <tt>interval_string</tt> should use the notation <tt>i h i m i s</tt> where
    # +i+ are integer values.
    def initialize(str)
      interval_string = str.strip.downcase
      @notation_pattern = PATTERN
      @time_hash = parse interval_string
    end

    # Parses <tt>interval_string</tt> and returns the total number of seconds
    # (Integer).
    #
    # Returns +nil+ if <tt>interval_string</tt> is nil.
    #
    # <tt>interval_string</tt> should use the notation <tt>i h i m i s</tt> where
    # +i+ are integer values.
    def self.in_seconds(interval_string)
      return unless interval_string

      new(interval_string).to_seconds
    end

    # Parses <tt>interval_string</tt> and returns the total number of seconds
    # (Integer).
    #
    # Returns +0+ if <tt>interval_string</tt> is nil.
    #
    # <tt>interval_string</tt> should use the notation <tt>i h i m i s</tt> where
    # +i+ are integer values.
    def self.in_seconds!(interval_string)
      self.in_seconds(interval_string).to_i
    end

    # Returns a hash with format <tt>{ h: Integer, m: Integer, s: Integer }</tt>
    def to_h
      @time_hash
    end

    # Returns a String representation for +self+.
    def to_s
      to_h.map { |pair| pair.reverse.join }.join ' '
    end

    # Returns the total number of seconds (Integer) for +self+.
    def to_seconds
      hours * 3600 + minutes * 60 + seconds
    end

    def method_missing(method, *args, &block)
      super unless METHODS.include?(method.to_sym)

      key = method.to_s[0].to_sym
      to_h.fetch key, 0
    end

    def respond_to_missing?(method_name, include_private = false)
      METHODS.include?(method_name.to_sym) || super
    end

    private

    # Parses <tt>interval_string</tt>.
    #
    # <tt>interval_string</tt> should use the notation <tt>i h i m i s</tt> where
    # +i+ are integer values.
    #
    # Parsing is case-insensitive and whitespace tolerant.
    def parse(interval_string)
      @notation_pattern.match(interval_string) do |match|
        match.named_captures
             .transform_keys(&:to_sym)
             .transform_values(&:to_i)
      end
    end
  end
end
