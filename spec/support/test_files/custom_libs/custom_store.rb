# frozen_string_literal: true

class CustomStore
  attr_reader :media_types

  def initialize(repo, **opts)
    @media_types = []
  end

  def supports?(mime)
  end
end
