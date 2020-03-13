# frozen_string_literal: true

require_relative '../../helpers/mockable'

# This class is a class for custom repository objects strictly for testing
# purposes.
class DummyStore
  include Mockable

  attr_reader :media_types, :name, :iiif_image_api, :service_url

  def initialize(repo, **opts)
    @iiif_image_api = true
    @media_types = %w[image/jpeg image/tiff]
    @name = 'Test Store'
    @service_url = 'http://example.org/iiif'
  end

  def attributes
    { name: name, service_url: service_url, iiif_image_api: iiif_image_api }
  end

  def store(request)
    ['path/to/stored_file.jpg', file_metadata, 'checksum']
  end

  def supports?(mime)
    media_types.include? mime
  end
end
