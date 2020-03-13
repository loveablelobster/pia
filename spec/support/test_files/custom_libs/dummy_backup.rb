# frozen_string_literal: true

require_relative '../../helpers/mockable'

# This class is a class for custom repository objects strictly for testing
# purposes.
class DummyBackup
  include Mockable

  attr_reader :media_types, :name, :iiif_image_api, :service_url

  def initialize(repo, **opts)
    @iiif_image_api = false
    @media_types = %w[image/jpeg image/tiff]
    @name = 'Test Backup'
    @service_url = 'https://example.org/permastore'
  end

  def attributes
    { name: name, service_url: service_url, iiif_image_api: iiif_image_api }
  end

  def store(request)
    ['path/to/backed_up_file.jpg', file_metadata, 'checksum']
  end

  def supports?(mime)
    media_types.include? mime
  end
end
