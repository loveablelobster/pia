# frozen_string_literal: true

require_relative 'hmac_authentication/signature'

module Pia
  #
  module HmacAuthentication

    def self.configure(app, **opts)
      app.opts[:hmac_key] = opts.fetch :hmac_key
      app.opts[:hmac] ||= {}
      app.opts[:hmac][:secret] = opts.fetch :hmac_secret
      app.opts[:hmac][:separator] = opts.fetch :hmac_separator, nil
      app.opts[:hmac][:hash_function] = opts.fetch :hmac_hash_function, nil
    end

    # Methods included in the request.
    module RequestMethods
      #
      def authenticate_upload
        auth_header = fetch_header 'HTTP_AUTHORIZATION'

        keys = %w[filename specify_user timestamp]
        signature = Signature.from_params(params, keys, roda_class.opts[:hmac])
          .with_file params.fetch('file')['tempfile']
      rescue KeyError => e
        if e.key == 'HTTP_AUTHORIZATION'
          log_msg = 'Attempt to upload file without HTTP_AUTHORIZATION header'
          status = 403
          msg = { message: 'Forbidden!' }
        else
          log_msg = "Request aborted. Missing element: #{e.key}."
          status = 111
          msg = { message: 'Bad request. Ignored.' }
        end
        roda_class.opts[:common_logger]&.warn log_msg
        halt [status, { 'Content-Type' => 'text/html' }, msg.to_json]
      end
    end
  end
end
