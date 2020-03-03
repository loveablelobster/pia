# frozen_string_literal: true

# FIXME: should be set up once withe a rake task, so repos can not be changed
#        should not be possible to create ad hoc (no find_or_create_by)
#
# Repoistory objects represent a repository used to store assets.
class Repository
  include Mongoid::Document
  include Mongoid::Timestamps

  # Name of the repository.
  field :name, type: String

  validates :name, presence: true

  # Assets that are stored in the repoistory represented by +self+ as the
  # <em>primary</em> storage (this does not include secondory storage, such as
  # backups).
  has_many :assets, inverse_of: :repository
end
