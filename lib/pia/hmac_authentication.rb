# frozen_string_literal: true

require_relative 'hmac_authentication/authorization_header'
require_relative 'hmac_authentication/signature'

module Pia
  # The HmacAuthentication plugin header authentication of requests using HMAC.
  #
  # TODO: needs more detailed documentation about the parameter properties
  # conteined in the message.
  module HmacAuthentication
    # Default message for a bad request.
    BAD_REQUEST = { message: 'Bad request. Ignored.' }.to_json.freeze

    # Default log message for a request with a bad HMAC signature.
    BAD_SIGNATURE = 'Attempt to upload file with a bad HMAC signature.'

    # Default message for an unauthorized request.
    FORBIDDEN = { message: 'Forbidden!' }.to_json.freeze

    # Content header for HTML.
    HTML = { 'Content-Type' => 'text/html' }.freeze

    # Default log message for a request with an invalit authorization header.
    INVALID = 'Attempt to upload file with an invalid HTTP_AUTHORIZATION header'

    # Default log message for a request without an authorization header.
    MISSING = 'Attempt to upload file without HTTP_AUTHORIZATION header'

    # Default log message for a request without an API key in the authorization
    # header.
    UNKNOWN = 'Attempt to upload file with an unknown API Key: '

    # Configures the pluging for +app+.
    #
    # ===== Options
    #
    # * <tt>:hmac_key</tt> - API key used in the authorization header.
    # * <tt>:hmac</tt> - Hash with HMAC options:
    #   * <tt>:secret</tt> - Secret used in the HMAC hash algorithm.
    #   * <tt>:separator</tt> - Characters used to separate the API key and the
    #     HMAC signatue.
    #   * <tt>:has_function</tt> - Cryptographic function used as hash algorithm
    #     (<em>default:</em> SHA512).
    def self.configure(app, **opts)
      app.opts[:hmac_key] ||= opts[:hmac_key]
      app.opts[:hmac_secret] ||= opts[:hmac_secret]
      app.opts[:hmac_separator] ||= opts[:hmac_separator]
      app.opts[:hmac_hash_function] ||= opts[:hmac_hash_function]
    end

    # Registers the Logger plugin with +app+.
    def self.load_dependencies(app, **_opts)
      app.plugin Logger
    end

    # Extends the application with a method to access the API key from the
    # options.
    module ClassMethods
      # Returns the API key.
      def key
        opts.fetch :hmac_key
      end
    end

    # Methods included in the request.
    module RequestMethods
      # Returns +self+ if the authorization header is valid and the HMAC
      # signature can be verifed. Halts the request otherwise.
      def authenticate_upload
        return self if param_signature.match? header_signature

        log BAD_SIGNATURE
        halt [401, HTML, FORBIDDEN]
      end

      # Returns the authoruzation header for +self+. Halts the request if the
      # header does not exist.
      def auth_header
        fetch_header 'HTTP_AUTHORIZATION'
      rescue KeyError
        log MISSING
        halt [403, HTML, FORBIDDEN]
      end

      # Returns the HMAC signature from the authorization header of the
      # request if the request if the API key can be verified. Halts the request
      # if the key does not match.
      def header_signature
        AuthorizationHeader.new(auth_header, separator: ':') do |h|
          return h.signature if h.verify(roda_class.key)

          log h.valid? ? UNKNOWN + h.key : INVALID
          halt [401, HTML, FORBIDDEN]
        end
      end

      # Returns a Signature object for the message contained in the parameters
      # for the request.
      def param_signature
        keys = %w[filename specify_user timestamp]
        sig_opts = { secret: roda_class.opts[:hmac_secret],
                     separator: roda_class.opts[:hmac_separator],
                     hash_function: roda_class.opts[:hmac_hash_function] }
        Signature.from_params(params, keys, sig_opts)
                 .with_file params.fetch('file')[:tempfile]
      rescue KeyError => e
        log "Request aborted. Missing element: #{e.key}."
        halt [111, HTML, BAD_REQUEST]
      end
    end
  end
end
