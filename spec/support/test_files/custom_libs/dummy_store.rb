# frozen_string_literal: true

require_relative '../../helpers/mockable'

# This class is a class for custom repository objects strictly for testing
# purposes.
class DummyStore
  include Mockable

  attr_reader :media_types, :name

  def initialize(repo, **opts)
    @media_types = %w[image/jpeg image/tiff]
    @name = 'Test Store'
  end

  def store(request)
    ['path/to/stored_file.jpg', file_metadata, 'checksum']
  end

  def supports?(mime)
    media_types.include? mime
  end
end
