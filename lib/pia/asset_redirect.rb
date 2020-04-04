# frozen_string_literal: true

module Pia
  # AssetRedirect objects form iiif conform URIs for an Asset
  class AssetRedirect
    # Asset object.
    attr_reader :asset

    # Returns a new instance for +asset+.
    def initialize(asset)
      @asset = asset
      return if iiif_image_api?

      raise 'Only redirects to iiif services are supported at this time'
    end

    # Returns a URI for the resource.
    #
    # If <tt>base_uri</tt> is passed, the returned URI will be a concatanation
    # of <tt>base_uri</tt> and the asset identifier.
    #
    # If <tt>params</tt> ar passes, a iiif URI will be returned (<tt>params</tt>
    # must contain valid keys and values to create a IIIF::URI).
    def build_uri(base_uri = nil, **params)
      if base_uri
        base_uri = base_uri.sub(%r{/$}, '')
        base_uri + '/' + asset.identifier
      else
        IIIF::URI.new(service_url, **params).to_uri.to_s
      end
    end

    # Returns a String with the file extension for the default output format of
    # the repository for the asset.
    def default_media_type
      asset.repository.default_output_format
    end

    # Returns a Hash with the default parameters to build a IIIF::URI for a
    # fullsize image.
    #
    # The default format is the #default_media_type. Pass the <tt>:format</tt>
    # option for a different format.
    #
    # Any defaults can be overridden by passing (see #iiif_params).
    def fullsize_params(**params)
      iiif_params&.update params
    end

    # Returns a String with a URI for a iiif resource.
    #
    # If no arguments are given, the URI will be built with default
    # #iiif_params. All arguments must be objects the implement #to_s.
    #
    # ===== Arguments
    #
    # * +region+ - Rectangular portion of the full image to be returned.
    # * +size+ - Dimensions to which the extracted region is to be scaled.
    # * +rotation+ - Degrees by which to rotate the image.
    # * +quality+ - Output quality.
    # * +format+ - Output format.
    def iiif(*args)
      params = %i[region size rotation quality format].zip(args).to_h.compact
      build_uri(**iiif_params(**params))
    end

    # Returns +true+ if the repository where the asset is stored supports the
    # iiif Image API.
    def iiif_image_api?
      asset.repository.iiif_image_api
    end

    # Returns a Hash with the parameters to build a IIID::URI.
    #
    # Will return +nil+ if the repository for the #asset does not implement the
    # iiif Image API.
    #
    # Any defaults can be overridden by passing options.
    #
    # ===== Options
    #
    # * <tt>:identifier</tt> - Identifier for the image.
    # * <tt>:region</tt> - Rectangular portion of the fulle image to be
    #   returned.
    # * <tt>:size</tt> - Diemensions to which the extracted region is to be
    #   scaled.
    # * <tt>:rotation</tt> - Degrees by which to rotate the image.
    # * <tt>:quality</tt> - Output quality.
    # * <tt>:format</tt> - Output format.
    def iiif_params(**opts)
      return unless iiif_image_api?

      { identifier: asset.identifier,
        region: :full,
        size: :max,
        rotation: 0,
        quality: :default,
        format: default_media_type }.update opts
    end

    # Returns a String with the URL for the iiif service where the asset can be
    # accessed.
    def service_url
      asset.repository.service_url
    end

    # Returns a Hash with the default parameters to build a IIIF::URI for a
    # thumbnail.
    #
    # The default size for thumbnails has a width of 128 pixels. To change the
    # size, pass the <tt>:size</tt> option.
    #
    # The default format is the #default_media_type. Pass the <tt>:format</tt>
    # option for a different format.
    #
    # Any defaults can be overridden by passing (see #iiif_params).
    def thumbnail_params(**opts)
      opts[:size] = "#{opts[:size]}," if opts[:size].is_a? Integer
      opts[:size] ||= '128,'
      iiif_params&.update opts
    end

    def method_missing(msg, *args, &block)
      msg = msg.to_sym
      if respond_to_missing? msg
        params = args.first || {}
        build_uri(**public_send("#{msg}_params".to_sym, **params)) ||
          asset.repository.public_send(msg)
      else
        super
      end
    end

    def respond_to_missing?(msg, include_private = false)
      %i[fullsize thumbnail].include?(msg.to_sym) || super
    end
  end
end
