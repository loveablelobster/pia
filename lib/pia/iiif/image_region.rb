# frozen_string_literal: true

module Pia
  module IIIF
    # ImageRegion objects define the rectangular portion of the full image to be
    # returned. A region can be specified by pixel coordinates, percentage or by
    # the values <tt>:full</tt> or <tt>:square</tt>.
    class ImageRegion
      # ===== Accepted arguments
      #
      # * <tt>:full</tt> - Specifies that the entire image should be returned.
      # * <tt>:square</tt> - The region is defined as an area where the width
      #   and height are both equal to the length of the shorter dimension of 
      #   the complete image.
      # * <tt>x, y, w, h</tt> - The region of the full image to be returned is
      #   specified in terms of absolute pixel values. The value of +x+
      #   represents the number of pixels from the 0 position on the horizontal
      #   axis. The value of +y+ represents the number of pixels from the 0
      #   position on the vertical axis. +w+ represents the width of the region
      #   and +h+ represents the height of the region in pixels.
      # * <tt>:pct, x, y, w, h</tt> - The region to be returned is specified as
      #   a sequence of percentages of the full image’s dimensions.
      def initialize(*args)
        sym = args.shift if args.first.is_a? Symbol
        @shorthand = sym if %i[full square].include? sym
        @percentage = true if sym == :pct
        self.rectangle = args
      end

      # Returns a String representation of +self+ that can be used as a path
      # segment in a URI.
      def to_s
        shorthand_str || rectangle_str
      end

      private

      # Returns the percentage prefix <tt>'pct:'</tt> if +self+ is initialized
      # with a rectangle in percantage (relative) notation.
      #
      # Returns an empty String otherwise.
      def percentage_str
        @percentage ? 'pct:' : ''
      end

      # Validates and assigns +coords+ to <tt>@rectangle</tt>.
      def rectangle=(coords)
        return if coords.empty?

        raise ArgumentError unless valid? coords

        @rectangle = coords
      end

      # If +self+ is initialized with a rectangle, returns the coordinates as a
      # string.
      def rectangle_str
        percentage_str + @rectangle.join(',')
      end

      # If +self+ is initialized with <tt>:full</tt> or <tt>square</tt>, returns
      # <tt>'full'</tt> or <tt>'square'</tt> respectively.
      #
      # Returns +nil+ otherwise.
      def shorthand_str
        @shorthand&.to_s
      end

      # Returns +true+ if there are four elements in +coords+ and all are 
      # numeric.
      def valid?(coords)
        kind = @percentage ? Numeric : Integer
        coords.size == 4 && coords.all? { |coord| coord.kind_of? kind }
      end
    end
  end
end
