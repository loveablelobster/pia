# frozen_string_literal: true

module Pia
  module IIIF
    COMPONENTS = %r/^(?<scheme>.+):\/{2}(?<host>[^\/]+)\/(?<prefix>.*)$/.freeze
    QUALITY = %i[color gray bitonal default].freeze

    # URI objects help building well formed HTTP or HTTPS URIs that conform to
    # the iiif Image API (https://iiif.io/api/image/2.1/).
    class URI
      # Object that represents the <em>format</em> parameter of the <em>iiif
      # Image API</em> (https://iiif.io/api/image/2.1/#format).
      #
      # The object must respond to #to_s with one of the following strings:
      # <tt>'jpg'</tt>, <tt>'tif'</tt>, <tt>'png'</tt>, <tt>'gif'</tt>,
      # <tt>'jp2'</tt>, <tt>'pdf'</tt>, or <tt>'webp'</tt>.
      attr_accessor :format

      # The host server on which the service resides.
      attr_accessor :host

      # The identifier of the requested image.
      attr_accessor :identifier

      # Array that contains the segments of the path to the IIIF service on the
      # host.
      attr_reader :prefix

      # Object that represents the <em>quality</em> parameter of the <em>iiif
      # Image API</em> (https://iiif.io/api/image/2.1/#quality).
      #
      # The object must respond to #to_s with one of the following strings:
      # <tt>'color'</tt>, <tt>'gray'</tt>, <tt>'bitonal'</tt>, or
      # <tt>'default'</tt>.
      attr_reader :quality

      # Object that represents the <em>region</em> parameter of the <em>iiif
      # Image API</em> (https://iiif.io/api/image/2.1/#region).
      #
      # The object must respond to #to_s and return a String that defines the
      # rectangular portion of the full image to be returned.
      attr_accessor :region

      # Object that represents the <em>rotation</em> parameter of the <em>iiif
      # Image API</em> (https://iiif.io/api/image/2.1/#rotation).
      #
      # The object must respond to #to_s and return a String any floating point
      # number between 0 and 360. For a mirrored image, prefix the floating
      # point numbr with +!+.
      attr_accessor :rotation

      # Indicates the use of the HTTP or HTTPS protocol in calling the service.
      attr_accessor :scheme

      # Object that represents the <em>size</em> parameter of the <em>iiif
      # Image API</em> (https://iiif.io/api/image/2.1/#size).
      #
      # The object must respond to #to_s and return a String that defines the
      # dimensions to which the extracted region is to be scaled.
      attr_accessor :size

      # Returns a new instance.
      #
      # ===== Arguments
      #
      # * <tt>base_url</tt> - A string with an HTTP or HTTPS url including
      #   for the service. Should contain <em>scheme</em>, <em>host</em>, and
      #   <em>prefix</em> of the image URI
      #   (https://iiif.io/api/image/2.1/#image-information-request-uri-syntax).
      #
      # ===== Options
      #
      # * <tt>:scheme</tt> - Scheme for the URL.
      # * <tt>:host</tt> - Server name.
      # * <tt>:prefix</tt> - Path on the server where the service is found.
      # * <tt>:identifier</tt> - Identifier for the image.
      # * <tt>:region</tt> - Rectangular portion of the fulle image to be
      #   returned.
      # * <tt>:size</tt> - Diemensions to which the extracted region is to be
      #   scaled.
      # * <tt>:rotation</tt> - Degrees by which to rotate the image.
      # * <tt>:quality</tt> - Output quality.
      # * <tt>:format</tt> - Output format.
      #
      # If <tt>base_url</tt> and <tt>:scheme</tt>, <tt>:host</tt>, or
      # <tt>:prefix</tt> options are given, the options will override
      # <em>scheme</em>, <em>host</em>, or <em>prefix</em> as specified in the
      # <tt>base_url</tt> paramter.
      def initialize(base_url = nil, **opts)
        @scheme = nil
        @host = nil
        @prefix = []
        self.attributes = URI.parse_uri base_url
        self.attributes = opts
        yield self if block_given?
      end

      # Parses values for #scheme, #host, and #prefix from +str+ and returns
      # them in a Hash.
      def self.parse_uri(str)
        COMPONENTS.match(str)&.named_captures
      end

      # Returns a String with the absolute path for the URI.
      #
      # This will be the full path to the iiif resource.
      def path
        prefix.push(identifier, region.to_s, size.to_s, rotation.to_s, resource)
              .join('/').prepend '/'
      end

      # Sets the #prefix attribute to +obj+.
      #
      # +obj+ could be an Array of path components, or a String with a path.
      def prefix=(obj)
        obj = obj.split('/') if obj.is_a? String
        @prefix = obj
      end

      # Sets the #quality attribute to +val+.
      #
      # +val+ must be a String or Symbol, and must be one of the accepted values
      # defined in QUALITY.
      def quality=(val)
        raise ArgumentError unless QUALITY.include? val.to_sym

        @quality = val
      end

      # Returns a String with the name of the requested resource on the server.
      def resource
        "#{quality}.#{format}"
      end

      # Returns a String for the full URI.
      def to_s
        "#{scheme}://#{host}#{path}"
      end

      # Returns an URI object.
      def to_uri
        uri_class = ::URI.const_get scheme.upcase
        uri_class.build host: host, path: path
      end

      private

      # Assigns +val+ to the attribute +attr+ (Symbol or String).
      def assign(attr, val)
        return unless respond_to? attr

        public_send attr, val
      end

      # Sets all instance variables of +self+ according to values in +hash+.
      #
      # The keys in +hash+ must be the names of the attributes for the instance
      # variables (e.g. <tt>'scheme'</tt> or <tt>:scheme</tt> for
      # <tt>@scheme</tt>).
      def attributes=(hash)
        return unless hash

        hash.transform_keys { |key| "#{key}=".to_sym }
            .each { |attr, val| assign attr, val }
      end
    end
  end
end
