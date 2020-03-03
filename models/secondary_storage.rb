# frozen_string_literal: true

# Copies represent additional versions of an asset that are stored in a
# different repository.
#
# This might be for backup reasons, or to store an unaltered version of an
# uploaded file elsewhere, if the {asset's primary
# repository}[rdoc-ref:Asset.repository] requires a file modifications.
class Copy
  include Mongoid::Document
  include Mongoid::Timestamps

  validates :repository, :uri, presence: true

  # The URI under which the version of the asset can be retrieved.
  field :uri, type: String

  # The repository where the asset copy represented by +self+ is stored.
  belongs_to :repository

  # The Asset of which +self+ is a copy.
  embedded_in :asset, inverse_of: :copies
end
