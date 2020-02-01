# frozen_string_literal: true

require_relative 'hmac_authentication/authorization_header'
require_relative 'hmac_authentication/signature'

module Pia
  #
  module HmacAuthentication
    BAD_REQUEST = { message: 'Bad request. Ignored.' }.to_json.freeze
    BAD_SIGNATURE = 'Attempt to upload file with a bad HMAC signature.'
    FORBIDDEN = { message: 'Forbidden!' }.to_json.freeze
    HTML = { 'Content-Type' => 'text/html' }.freeze
    INVALID = 'Attempt to upload file with an invalid HTTP_AUTHORIZATION header'
    MISSING = 'Attempt to upload file without HTTP_AUTHORIZATION header'
    UNKNOWN = 'Attempt to upload file with an unknown API Key: '

    def self.configure(app, **opts)
      app.opts[:hmac_key] = opts.fetch :hmac_key
      app.opts[:hmac] ||= {}
      app.opts[:hmac][:secret] = opts.fetch :hmac_secret
      app.opts[:hmac][:separator] = opts.fetch :hmac_separator, nil
      app.opts[:hmac][:hash_function] = opts.fetch :hmac_hash_function, nil
    end

    module ClassMethods
      #
      def key
        opts.fetch :hmac_key
      end
    end

    # Methods included in the request.
    module RequestMethods
      #
      def authenticate_upload
        return self if param_signature.match? header_signature

        log BAD_SIGNATURE
        halt [401, HTML, FORBIDDEN]
      end

      def auth_header
        fetch_header 'HTTP_AUTHORIZATION'
      rescue KeyError
        log MISSING
        halt [403, HTML, FORBIDDEN]
      end

      #
      def header_signature
        AuthorizationHeader.new(auth_header, separator: ':') do |h|
          return h.signature if h.verify(roda_class.key)

          log h.valid? ? UNKNOWN + h.key : INVALID
          halt [401, HTML, FORBIDDEN]
        end
      end

      #
      def param_signature
        keys = %w[filename specify_user timestamp]
        Signature.from_params(params, keys, roda_class.opts[:hmac])
                 .with_file params.fetch('file')[:tempfile]
      rescue KeyError => e
        log "Request aborted. Missing element: #{e.key}."
        halt [111, HTML, BAD_REQUEST]
      end
    end
  end
end
