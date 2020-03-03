# frozen_string_literal: true

# FIXME: mongo ignores time zone, uses UTC, this affects the values of any
#        time stamps fields
#
# FileMetadataSet objects contain metadata of a file that got uploaded and is
# stored in one of the repositories.
#
# A metadata set must have a #setname.
class FileMetadataSet
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  embedded_in :asset, inverse_of: :file_metadata_sets

  # Required field that identifies the metadata as belonging to one of three
  # sets:
  # * +stored+: metadata of the file as it is stored in the repository.
  # * +dropped+: metadata of the uploaded file that was lost during file
  #   processing prior to storage.
  # * +withheld+: metadata that was redacted from the file.
  field :setname, type: String, default: 'stored'

  validates :setname,
            inclusion: { in: %w[stored dropped withheld] },
            presence: true
end
