# frozen_string_literal: true

require 'logger'
require 'mongoid'
require 'roda'
require 'rack'
require 'rack/contrib'

require_relative 'lib/pia'
require_relative 'models/asset'
require_relative 'models/copy'
require_relative 'models/file_metadata_set'
require_relative 'models/repository'

#
class PiaApp < Roda
  def self.load_config
    file = File.open 'config/config.yaml'
    config = Psych.safe_load(file, symbolize_names: true)[environment]
    PiaApp.opts[:hmac_key] = config.delete(:key) || ENV['pia_key']
    PiaApp.opts[:hmac_secret] = config.delete(:secret) || ENV['pia_secret']
    request_exp_time = config.delete :request_exp_time
    PiaApp.opts[:request_exp_time] = Pia::Duration.in_seconds request_exp_time
    config.each { |key, value| PiaApp.opts[key] = value }
  end

  plugin :environments

  config = PiaApp.load_config
  Mongoid.load! File.expand_path('config/mongoid.yaml')
  
  plugin :all_verbs
  plugin :common_logger, ::Logger.new(STDOUT)
  plugin Logger
  plugin Pia::Requestinterval
  plugin Pia::HmacAuthentication
  plugin Pia::RepositoryStack
  use Rack::Access, '/asset/upload/' => PiaApp.opts[:hosts]

  repositories.each do |repo|
    Repository.find_or_create_by(repo.attributes)
  end

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

      # TODO: document: upload params contains 'is_public' element
      r.on 'upload' do
        r.post do
          r.validate_timestamp.authenticate_upload
          Pia::AssetCreator.call r.filename, store(r), r.params['is_public']
        end

        'should handle post requests'
      end

      r.on String do |id|
        asset = Asset.find id

        r.get do
          asset_uri = Pia::AssetRedirect.new asset

          # halt unless asset.public || validate_timestamp.authorized
          r.is 'fullsize' do
            r.redirect asset_uri.fullsize
          end

          r.is 'thumbnail' do
            size = r.params.fetch('scale', 128).to_i
            r.redirect asset_uri.thumbnail(size: size)
          end

          # iiif
          r.on String,
               String,
               String,
               String do |region, size, rotation, quality_format|
            quality, format = quality_format.split '.'
            r.redirect asset_uri.iiif(region, size, rotation, quality, format)
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
