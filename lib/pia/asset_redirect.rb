# frozen_string_literal: true

module Pia
  # AssetRedirect objects form iiif conform URIs for an Asset
  class AssetRedirect
    SHORTHAND = %i[fullsize thumbnail].freeze
    attr_reader :asset

    def initialize(asset)
      @asset = asset
      return if iiif_image_api?

      raise 'Only redirects to iiif services are supported at this time'
    end

    def build_uri(params)
      IIIF::URI.new(service_url, **params).to_uri
    end

    def default_format
      :jpg
    end

    def fullsize_params
      {
        identifier: asset.identifier,
        refion: :full,
        size: :max,
        rotation: 0,
        quality: :default,
        format: default_format
      }
    end

    def iiif_image_api?
      asset.repository.iiif_image_api
    end

    def service_url
      asset.repository.service_url
    end

    def thumbnail_params(**size)
      size.merge {
      }
    end

    def method_missing(msg, *args, &block)
      msg = msg.to_sym
      if SHORTHAND.include? msg
        params_msg = msg.to_s + '_params'
        build_uri public_send(params_msg.to_sym, *args, &block)
      else
        super
      end
    end

    def respond_to?(msg, include_private = false)
      SHORTHAND.include?(msg.to_sym) || super
    end
  end
end
