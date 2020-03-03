# frozen_string_literal: true

# Copy objects represent copies or versions of the asset stored in a
# different the main repository.
#
# This might be for backup reasons, or to store an unaltered version of an
# uploaded file elsewhere, if the {asset's primary
# repository}[rdoc-ref:Asset.repository] requires a file modifications.
class Copy
  include Mongoid::Document
  include Mongoid::Timestamps

  # The Asset of which +self+ is a copy.
  embedded_in :asset, inverse_of: :copies

  # The repository where the asset copy represented by +self+ is stored.
  belongs_to :repository

  # The URI under which the version of the asset can be retrieved.
  field :uri, type: String

  validates :repository, :uri, presence: true
end
