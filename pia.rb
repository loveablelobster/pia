# frozen_string_literal: true

require 'logger'
require 'roda'
require 'rack'
require 'rack/contrib'

require_relative 'lib/pia'

#
module Pia
  class Pia < Roda
    def self.load_config
      file = File.open 'config/config.yaml'
      config = Psych.safe_load(file, symbolize_names: true)[environment]
      Pia.opts[:hmac_key] = config.delete(:key) || ENV['pia_key']
      Pia.opts[:hmac_secret] = config.delete(:secret) || ENV['pia_secret']
      request_exp_time = config.delete :request_exp_time
      Pia.opts[:request_exp_time] = Duration.in_seconds request_exp_time
      config.each { |key, value| Pia.opts[key] = value }
    end

    plugin :environments

    config = Pia.load_config
    
    plugin :all_verbs
    plugin :common_logger, ::Logger.new(STDOUT)
    plugin Logger
    plugin Requestinterval
    plugin HmacAuthentication
    plugin RepositoryStack
    use Rack::Access, '/asset/upload/' => Pia.opts[:hosts]

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
            store r
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
