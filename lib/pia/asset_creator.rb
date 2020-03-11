# frozen_string_literal: true

require_relative '../../models/asset'
require_relative '../../models/repository'

module Pia
  # AssetCreator instances are service objects that create Asset objects from
  # the Hash returned by the
  # {RepositoryStack#store}[rdoc-ref:Pia::RepositoryStack.store] method.
  class AssetCreator
    # Returns a new instance.
    def initialize(asset_model: Asset, repository_model: Repository)
      @asset_model = asset_model
      @repository_model = repository_model
    end

    # Creates a new instance and calls #call.
    #
    # ===== Arguments
    #
    # * +filename+ - Name (String) of the file as uploaded.
    # * <tt>storage_infor</tt> - Hash with repository names as keys, arrays as
    #   values, where each value array consists of filepath, metadata, and
    #   checksum.
    # * <tt>public_flag</tt> - Boolean, mandates if the asset is publicly
    #   accessible or will require authentication.
    def self.call(filename, storage_info, public_flag)
      new.call(filename, storage_info, public_flag)
    end

    # Creates an Asset and returns an abridged description as JSON.
    #
    # ===== Arguments
    #
    # * +filename+ - Name (String) of the file as uploaded.
    # * <tt>storage_infor</tt> - Hash with repository names as keys, arrays as
    #   values, where each value array consists of filepath, metadata, and
    #   checksum.
    # * <tt>public_flag</tt> - Boolean, mandates if the asset is publicly
    #   accessible or will require authentication.
    def call(filename, storage_info, public_flag)
      primary_store = storage_info.keys.first
      asset = create filename,
                     repository(primary_store),
                     storage_info[primary_store],
                     copies(storage_info),
                     public_flag
      json_from asset
    end

    private

    # Returns the basename for +file+ without extension, to be used as the
    # asset ID.
    def asset_id(file)
      File.basename file, '.*'
    end

    # Extracts information on secondary storage from <tt>storage_info</tt> and
    # returns an Array of hashes with attributes to create Copy objects.
    #
    # ===== Arguments
    #
    # * <tt>storage_infor</tt> - Hash with repository names as keys, arrays as
    #   values, where each value array consists of filepath, metadata, and
    #   checksum.
    def copies(storage_info)
      secondary_storages = storage_info.keys[1..-1]
      storage_info.slice(*secondary_storages)
                  .transform_values(&:first)
                  .map { |k, v| { repository: repository(k), uri: v } }
    end

    # Creates an Asset object from the arguments.
    #
    # ===== Arguments
    #
    # * +filename+ - Original filename of the asset as uploaded.
    # * +repository+ - Primary repository where the asset is stored.
    # * +stored+ - Array containg the path where the file is stored, the file's
    #   metadata, and checksum.
    # * +copies+ - Array of Hashes with attributes to create Copy objects.
    # * <tt>public_flag</tt> - Boolean, mandates if the asset is publicly
    #   accessible or will require authentication.
    def create(filename, repository, stored, copies, public_flag)
      path, file_meta, checksum = stored
      @asset_model.create! asset_id: asset_id(path),
                           identifier: path,
                           public: public_flag,
                           filename: filename,
                           media_type: media_type(file_meta, path),
                           md5sum: checksum,
                           repository: repository,
                           file_metadata_sets: file_meta,
                           copies: copies
    end

    # Returns an abridged JSON description of +asset+, to be returned in the
    # HTTP response body upon successful upload.
    #
    # FIXME: this should go to a presenter.
    def json_from(asset)
      { asset_identifier: asset.asset_id,
        resource_identifier: asset.identifier,
        mime_type: asset.media_type,
        capture_device: asset.capture_device,
        file_created_date: asset.create_date('%Y-%m-%d %H:%M:%S.%6L'),
        date_imaged: asset.date_imaged,
        copyright_holder: asset.copyright,
        checksum: asset.md5sum }.to_json
    end

    # Returns the media type (MIME type) for the asset as stored in the primary
    # repository.
    #
    # ===== Arguments
    #
    # * +meta+ - an array of hashes containg file metadata.
    # * +file+ - the file basename with extension.
    #
    # Will first look for the <em>MIMEType</em> EXIF tag in the metadata hashes.
    # If the tag is not present, will look up the media type by extension.
    def media_type(meta, file)
      tags = meta.inject(&:merge)
      tags.fetch 'MIMEType', Rack::Mime.mime_type(File.extname(file))
    end

    # Returns the Repository object for +name+.
    def repository(name)
      @repository_model.find_or_create_by name: name
    end
  end
end
