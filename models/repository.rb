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
  index({ name: 1 }, unique: true, name: 'repository_index')

  # +true+ if the service where assets stored in the repository implements the
  # <em>iiif image api</em>.
  field :iiif_image_api, type: Boolean, default: false

  # The Base URL where assets stored in the repository represented by +self+ can
  # be accessed.
  field :service_url, as: :fullsize, type: String

  # The default media type of files served by thg repository.
  field :default_output_format, type: String

  # Assets that are stored in the repoistory represented by +self+ as the
  # <em>primary</em> storage (this does not include secondory storage, such as
  # backups).
  has_many :assets, inverse_of: :repository
end
