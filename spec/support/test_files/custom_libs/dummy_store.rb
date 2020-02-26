# frozen_string_literal: true

# This class is a class for custom repository objects strictly for testing
# purposes.
class DummyStore
  attr_reader :media_types, :name

  def initialize(repo, **opts)
    @media_types = %w[image/jpeg image/tiff]
    @name = 'Test Store'
  end

  def store(request)
    'return something nice'
  end

  def supports?(mime)
    media_types.include? mime
  end
end
