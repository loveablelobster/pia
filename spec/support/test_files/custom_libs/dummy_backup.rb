# frozen_string_literal: true

require_relative '../../helpers/mockable'

# This class is a class for custom repository objects strictly for testing
# purposes.
class DummyBackup
  include Mockable

  attr_reader :media_types, :name

  def initialize(repo, **opts)
    @media_types = %w[image/jpeg image/tiff]
    @name = 'Test Backup'
  end

  def store(request)
    ['path/to/backed_up_file.jpg', file_metadata, 'checksum']
  end

  def supports?(mime)
    media_types.include? mime
  end
end
