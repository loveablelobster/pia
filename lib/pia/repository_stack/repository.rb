# frozen_string_literal: true

module Pia
  module RepositoryStack
    # Array of file metadata setnames for Pia::Model::FileMetadataSet
    # documents to be included into the Pia::Model::Asset document.
    METADATA_SETS = %w[dropped redacted].freeze

    # EXIF tags that relate to the filesystem.
    FILESTAT_TAGS = %w[SourceFile FileName Directory FilePermissions
                       FileModifyDate FileAccessDate FileInodeChangeDate].freeze

    # Repository objects are storage units that manage a storage directory and
    # can automatically process files that are being stored.
    class Repository
      # +true+ if the service where assets stored in the repository implements the
      # <em>iiif image api</em>.
      attr_reader :iiif_image_api

      # Array of media (MIME) types (Strings) that are supported by the
      # repository.
      attr_reader :media_types

      # Name for the repository.
      attr_reader :name

      # FilePipeline::Pipeline object configured with the file processing
      # required for the repository.
      attr_reader :processing

      # Hash containing the components for the base URL for the service where
      # assets stored in +self+ can be accessed:
      # * <tt>:scheme</tt> - <tt>'http'</tt> or <tt>'https'</tt>.
      # * <tt>:server</tt> - name of the server (e.g. <tt>'example.com'</tt>).
      # * <tt>:prefix</tt> - path on the server (e.g. <tt>'iiif'</tt>).
      #
      # The examples above would result in the URL
      # <tt>http://example.com/iiif/</tt>.
      attr_reader :service_url

      # FolderStash::FileUsher object that manages the storage directory.
      attr_reader :storage

      # Returns a new instance.
      #
      # ===== Arguments
      #
      # * +stack+ - object that contains information about the working directory
      #   (must respond to <tt>:workdir</tt>).
      #
      # ===== Options
      #
      # * +name+ - name of the repository (String), if none provided will be an
      #   integer.
      # * <tt>media_types</tt> - Array of media types (Strings, e.g.
      #   <tt>'image/jpeg'</tt>).
      # * <tt>:file_processing</tt> - Hash with options to set up a
      #   FilePipeline::Pipeline object for file processing.
      # * <tt>:storage_directory</tt> - Path to the directory where processed
      #   files are to be stored.
      # * <tt>:storage_options</tt> - Hash with options to set up a
      #   FolderStash::FileUsher object that will handle storage management.
      # * <tt>:service_url</tt> - Hash with options to configure the base URL
      #   where files stored in the repository can be accessed.
      def initialize(stack, **opts)
        mimes = opts.fetch :media_types, []
        @iiif_image_api = opts.delete :iiif_image_api
        @media_types = Set.new mimes
        @name = opts.fetch :name, stack.repositories.count
        @service_url = opts.delete :service_url
        @stack = stack
        self.processing = opts
        self.storage = opts
      end

      # Returns a Hash with attributes for +self+.
      def attributes(keys = %i[name service_url iiif_image_api])
        keys.each_with_object({}) { |key, hsh| hsh[key] = public_send key }
      end

      # Will process +file+ as configured in #processing and store the processed
      # version in the storage directory.
      #
      # Returns an Array with:
      # * path to the stored file
      # * Array of file metadata sets
      # * MD5 checksum for the processed file
      #
      # The Array of file metadata contains three Hashes which represent
      # metadata sets. Each Hash has a key <tt>:setname</tt> that designated the
      # set. There are three discrete metadata sets:
      # * +stored+ - metadata for the processed file as stored on the servere,
      #   except file stat specific tags (defined in FILESTAT_TAGS)
      # * +dropped+ - metadata of the original file, that was not preserved
      #   during file processing
      # * +withheld+ - metadata tags that may contain sensitive data and were
      #   redacted from the tag
      #
      # Note that this method does not verify that the media type is supported.
      # An unsupported media type might cause an error during processing.
      def store(file)
        stored_file, metadata = process stash(file)
        metadata.map! do |set|
          set.delete_if { |key, _| FILESTAT_TAGS.include? key }
             .transform_values { |v| v.is_a?(Rational) ? v.to_s : v }
        end
        checksum = Digest::MD5.file(File.join(storage.directory, stored_file))
                              .hexdigest
        [stored_file, metadata, checksum]
      end

      # Returns +true+ if <tt>media_type</tt> is included in #media_types or if
      # +self+ does not have any media type restrictions.
      def supports?(media_type)
        return true if media_types.empty?

        media_types.include? media_type
      end

      private

      # Sets the private @processing attribute of +self+ a
      # FilePipeline::Pipeline object configured according to +settings+.
      #
      # +settings+ should contain the key <tt>:file_processing</tt>.
      def processing=(settings)
        @processing = FilePipeline::Pipeline.new do |pipeline|
          operations = settings.delete :file_processing
          operations&.each do |op, opts|
            pipeline.define_operation op, opts.transform_keys(&:to_sym)
          end
        end
      end

      # Sets the private @storage attribute of +self+ to a
      # FolderStash::FileUsher object configured according to +settings+.
      #
      # +settings+ should contain the keys to <tt>:storage_directory</tt> and
      # <tt>:storage_options</tt>.
      def storage=(settings)
        dir = settings.delete :storage_directory
        opts = settings.delete(:storage_options)&.transform_keys(&:to_sym) || {}
        @storage = FolderStash::FileUsher.new(dir, **opts)
      end

      # Returns an Array of Hashes with metadata from <tt>versioned_file</tt>,
      # where each Hash is a set of metadata (<tt>:stored</tt>,
      # <tt>:dropped</tt>, and <tt>:withheld</tt> respectively).
      def collect_metadata(versioned_file)
        metadata = versioned_file.metadata.merge(setname: 'stored')
        METADATA_SETS.each_with_object([metadata]) do |set, coll|
          setname = set == 'redacted' ? 'withheld' : set
          coll << versioned_file.captured_data_with("#{set}_exif_data".to_sym)
                                .reduce({}, &:merge)
                                .merge(setname: setname)
        end
      end

      # Processes and finalizes <tt>versioned_file</tt> and stores the
      # processed file in the storage directory.
      #
      # Returns the path to the stored file and an Array of file metadata sets
      # for <tt>:stored</tt>, <tt>:dropped</tt>, and <tt>withheld</tt>
      # respectively.
      def process(versioned_file)
        processing.apply_to versioned_file
        file_metadata = collect_metadata versioned_file
        processed = versioned_file.finalize(overwrite: true)
        stored = storage.move processed, pathtype: :branch
        [stored, file_metadata]
      end

      # Creates a new FilePipeline::VersionedFile from +file+ in the working
      # directory.
      def stash(file)
        basename = SecureRandom.uuid + File.extname(file)
        stash_file = File.join @stack.workdir, basename
        File.open(stash_file, 'wb') { |f| f.write(File.new(file).read) }
        FilePipeline::VersionedFile.new stash_file
      end
    end
  end
end
