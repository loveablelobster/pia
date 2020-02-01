# frozen_string_literal: true

module Pia
  module HmacAuthentication
    # An AuthorizationHeader object wraps an <em>HTTP_AUTHORIZATION</em> header,
    # allows validation (ensuring the header has the right format), verification
    # (ensuring the API key sent in the header matches), and convenient acces to
    # the HMAC signature contained.
    #
    # The value of the header must contain an API key, a separator, and the
    # hashed (HMAC) signature.
    class AuthorizationHeader
      # Value of the <em>HTTP_AUTHORIZATION</em> header (String).
      attr_reader :header

      # API key sent in the <em>HTTP_AUTHORIZATION</em> header (String).
      attr_reader :key

      # Character (String) separating the API key and the hashed signature in
      # the header value.
      attr_reader :separator

      # Hashed (HMAC) signature (String), sent in the
      # <em>HTTP_AUTHORIZATION</em> header.
      attr_reader :signature

      # Returns a new instance.
      #
      # ===== Arguments
      #
      # * +header+: Value of the <em>HTTP_AUTHORIZATION</em> header to be
      #   wrapped (String).
      # * +separator+: Character (sequence) separating the API key and hashed
      #   signatur (String, <em>default: ':'</em>)
      def initialize(header, separator: ':')
        @header = header
        @separator = separator
        @key, @signature = catch(:invalid) do
          elements = header.split(separator).delete_if { |e| e.empty? }
          throw :invalid unless elements.size == 2
          elements
        end
        yield self if block_given?
      end

      # Returns +true+ if +self+ has both #key and #signature, +false+
      # otherwise.
      def valid?
        key && signature ? true : false
      end

      # Returns +self+ if <tt>api_key</tt> matches #key.
      def verify(api_key)
        self if valid? && Rack::Utils.secure_compare(api_key, key)
      end
    end
  end
end
