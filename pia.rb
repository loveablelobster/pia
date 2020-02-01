# frozen_string_literal: true

require 'logger'
require 'roda'
require 'rack'
require 'rack/contrib'

require_relative 'lib/pia'

#
module Pia
  class Pia < Roda
    plugin :all_verbs
    plugin :common_logger, ::Logger.new(STDOUT)
    plugin Logger
    plugin Requestinterval
    plugin HmacAuthentication,
           hmac_key: 'testkey',
           hmac_secret: 'testsecret',
           hmac_separator: '|',
           hmac_hash_function: 'SHA256'

    # FIXME: move to proper settings
    Roda.opts[:key] = 'testkey' # FIXME: duplicated in spec/web_spec.rb
    Roda.opts[:hosts] = ['127.0.0.1', '0:0:0:0:0:0:0:1']

    use Rack::Access, '/asset/upload/' => Roda.opts[:hosts]

    route do |r|
      r.root do
        'Server is running!'
      end

      r.on 'asset' do
        r.is do
          r.get do
            'Needs params'
          end
        end

        r.on 'upload' do
          r.post do
            r.validate_timestamp.authenticate_upload
            "posting #{r.params['specify_user']}, #{r.params['filename']}"\
            "#{r.params['timestamp']}, #{r.params['file']}"
          end

          'should handle post requests'
        end

        r.on String do |id|
          # TODO: find asset

          r.get do
            r.is 'fullsize' do
              "#{id} in full size"
            end

            r.is 'thumbnail' do
              "#{id} as thumbnail"
            end

            # iiif
            r.on String, String, String, String do |region, size, rotation, quality_format|
              "#{id}/#{region}/#{size}/#{rotation}/#{quality_format}"
            end
          end

          r.delete do
            r.is 'delete' do
              r.validate_timestamp
              "should delete #{id} filename: #{r['filename']} timestamp: #{r['timestamp']}"
            end
          end
        end
      end
    end
  end
end
