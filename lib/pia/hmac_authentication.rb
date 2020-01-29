# frozen_string_literal: true

module Pia
  #
  module HmacAuthentication

    def self.configure(app, **opts)
      app.opts[:key] = opts.fetch :key
      app.opts[:secret] = opts.fetch :secret
    end

    # Methods included in the request.
    module RequestMethods
      #
      def authenticate_upload
        auth_header = fetch_header 'HTTP_AUTHORIZATION'

        # handle by a class the creates the signature
        keys = %w[file filename specify_user timestamp]
        file, filename, username = keys.collect { |key| params.fetch key }
      rescue KeyError => e
        if e.key == 'HTTP_AUTHORIZATION'
          roda_class.opts[:common_logger]
            &.warn 'Attempt to upload file without HTTP_AUTHORIZATION header'
            halt [403,
                  { 'Content-Type' => 'text/html' },
                  { message: 'Forbidden!' }.to_json]
        else
          roda_class.opts[:common_logger]
            &.warn "Request aborted. Missing element: #{e.key}."
          halt [111,
                { 'Content-Type' => 'text/html' },
                { message: 'Bad request. Ignored.' }.to_json]
        end
      end
    end
  end
end
