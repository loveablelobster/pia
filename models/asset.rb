# frozen_string_literal: true

# Asset objects represent digitial assets managed by Pia and stored on one of
# the repositories.
class Asset
  include Mongoid::Document
  include Mongoid::Timestamps

  # The repository that serves as the primary (main) storage location for the
  # asset.
  belongs_to :repository, inverse_of: :assets

  field :_id, type: String, overwrite: true, default: -> { asset_id }

  # ID for the document. This will be the randomized filename without the
  # extension.
  field :asset_id, type: String

  index({ asset_id: 1 }, unique: true, name: 'asset_index')

  # The full URI under which the file is stored in the repository.
  #
  # This will be the iiif <em>identifier</em> for direct access on a iiif
  # server.
  field :identifier, type: String

  # Flag that mandates if the file can be accessed publicly or requires
  # authentication.
  field :public, type: Boolean, default: true

  # Original filename of the asset at the time of upload (filenames will be
  # randomized in the repository).
  field :filename, type: String

  # Media type (MIME type) for the file stored on the primary repository.
  field :media_type, type: String

  # MD5 Checksum for the asset as stored on the primary repository.
  field :md5sum, type: String

  # File Metadata Sets contain a stored asset's file metadata plus metadata for
  # the file at the time of upload, including metadata that was lost during
  # processing or withheld.
  embeds_many :file_metadata_sets, inverse_of: :asset

  # Copies are versions of the asset that are stored in addition to the main
  # version stored in the repository handling the asset's mediatype.
  embeds_many :copies, inverse_of: :asset

  validates :asset_id, :identifier, :repository, presence: true

  # Searches the #file_metadata_sets for +tags+ and returns the first value
  # found, or +nil+ if none is found.
  #
  # Search is restricted to metadata that is not withheld.
  def fetch_metadata(*tags)
    file_metadata_sets.where(:setname.not => 'withheld')
                      .pluck(*tags)
                      .flatten.compact.first
  end

  # Returns a String with information about the device used to capture the
  # image. The value is concatanated from the <em>Make</em>, <em>Model</em>, and
  # <em>LensModel</em> EXIF tags.
  #
  # NOTE: The value will be truncated to 128 characters, because the
  # corresponding column <tt>CaptureDevice</tt> in the <tt>attachment</tt> table
  # of the Specify schema (Schema Version 2.6) is max 128 characters long.
  def capture_device
    val = %w[Make Model LensModel].map { |tag| fetch_metadata tag }
                                  .compact.join ', '
    val = val[0..127] unless val.size <= 128
    val
  end

  # Returns a String with the value for the <em>Copyright</em> EXIF tag.
  #
  # Returns +nil+ if the tag is not present or withheld.
  def copyright
    fetch_metadata 'Copyright'
  end

  # Returns a Time object for the <em>CreateDate</em> EXIF tag.
  #
  # If the tag is not present in the metadata, returns the value for the
  # <em>DateTimeDigitized</em> tag.
  #
  # Returns +nil+ if neither tag is present, or if the tags are withheld.
  #
  # If the optional +format+ argument (a formatter string) is given, returns a
  # timestamp (String).
  def create_date(format = nil)
    val = fetch_metadata 'CreateDate', 'DateTimeDigitized'
    return val unless format && val

    val.strftime format
  end

  # Returns a Time object for the <em>DateTimeOriginal</em> EXIF tag.
  #
  # If the tag is not present in the metadata, returns the value for the
  # <em>CreateDate</em> or <em>DateTimeDigitized</em> tags, respectively.
  #
  # Returns +nil+ if neither tag is present, or if the tags are the withheld.
  #
  # If the optional +format+ argument (a formatter string) is given, returns a
  # timestamp (String).
  def date_imaged(format = nil)
    val = fetch_metadata 'DateTimeOriginal', 'CreateDate', 'DateTimeDigitized'
    return val unless format && val

    val.strftime format
  end
end
