# frozen_string_literal: true

module Pia
  module HmacAuthentication
    # Signature objects contain a message to be encrypted for HMAC
    # authentciation.
    class Signature
      # MD5 Checksum for the the file (if any) contained in a multipart request.
      attr_reader :file_md5

      # Algorithm used to hash the #message.
      attr_reader :hash_function

      # Array of values for properties contained in a multipart request.
      attr_reader :elements

      # String used to join the #elements.
      attr_reader :separator

      # Returns a new instance.
      #
      # ===== Arguments
      #
      # * +elements+ - Array of strings that will be the body of the hashed
      #   message.
      # * +file+: - File whose MD5 checksum will be part of the body of the
      #   hashes message (_optional_).
      # * <tt>hash_function</tt> - Name of the cryptographic algorithm used to
      #   hash the message. <em>Default:</em> <tt>'SHA512'</tt>.
      # * +secret+ - String that is the key to encrypt the message with.
      # * +separator+ - String used to join the #elements when generating the
      #   message body.
      def initialize(elements = [],
                     file: nil,
                     hash_function: nil,
                     secret:,
                     separator: nil)
        self.file_md5 = file
        @hash_function = hash_function || 'SHA512'
        @elements = elements
        @secret = secret
        @separator = separator || '|'
      end

      # Creates a new instance from the +params+ hash of a request, where the
      # message will include any element included in +keys+ and +options+ from
      # the application.
      #
      # Keys must be strings.
      def self.from_params(params, keys, options)
        signature = Signature.new **options
        keys.each_with_object(signature) { |key, sig| sig << params.fetch(key) }
      end

      # Adds +element+ to #elements.
      def <<(element)
        elements << element
      end

      # Adds the <em>MD5 checksum</em> for file to the message body.
      def file_md5=(file)
        file ||= yield if block_given?
        return unless file

        @file_md5 = Digest::MD5.file(file).hexdigest
      end

      # Returns the hexdigest for #message hashed with the #hash_function using
      # the secret.
      def hexdigest
        OpenSSL::HMAC.hexdigest hash_function, @secret, message
      end

      # Securely compares the #hexdigest of +self+ to another HMAC hexdigest.
      def match?(other)
        Rack::Utils.secure_compare hexdigest, other
      end

      # Returns a String of all #elements concatenated with the optional
      # #file_md5 checksum joined with the #separator+.
      def message
        [elements, file_md5].flatten.compact.join separator
      end

      alias with_file file_md5=
    end
  end
end
