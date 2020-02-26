# frozen_string_literal: true

require 'set'

require_relative 'repository_stack/repository'
require_relative 'repository_stack/repository_stack'

module Pia
  # The RepositoryStack plugin facilitates storage of files that are sent with
  # in multipart POST requests.
  #
  # The plugin uses Repository objects to handle file processing and storage.
  # It can have multiple Repository objects, and file type restrictions are
  # handled by each object.
  #
  # When a file is sent, the #store method will iterate over the repositories
  # and store the file in the first repository that handles the file's
  # mediatype. Iteration will continue after that, so that a file can be stored
  # in multiple repositories.
  #
  # Repositories can either be added by passing an array of repository objects
  # as the <tt>:repositories</tt> option, or having them created from a
  # configuration file in YAML format using a RepositoryStack object (see the
  # documentation of the RepositoryStack class for details). When using a
  # RepositoryStack object, make sure that the <tt>config/repositories.yaml</tt>
  # file exists in the working directory, or pass the path to a config file with
  # the <tt>:repository_config</tt> option.
  #
  # When using multiple repositories with a FolderStash::FileUsher object, make
  # sure link locations are not in the same directory.
  module RepositoryStack
    # Configures the plugin for +app+.
    #
    # ===== Options
    #
    # * <tt>:repository_config</tt> - Path to YAML file to be used to create
    #   repositories with a RepositoryStack object.
    # * <tt>:repositories</tt> - Array of repository objects to use with the
    #   plugin.
    def self.configure(app, **opts)
      app.opts[:repository_config] ||= opts[:repository_config]
      app.opts[:repositories] ||=
        opts[:repositories] ||
        RepositoryStack.new(app.opts[:repository_config]).repositories
    end

    # Registers the Logger plugin with +app+.
    def self.load_dependencies(app, **_opts)
      app.plugin Logger
    end

    # Extends the application with methods for media type restrictions and
    # repositories.
    module ClassMethods
      # Returns an Array of media types that are supported by the Roda
      # application.
      def supported_media_types
        repositories.map { |repo| repo.media_types.to_a }.flatten.uniq
      end

      # Returns the repository objects configured for the application.
      def repositories
        opts[:repositories]
      end
    end

    # Includes methods to access respository objects and store files into the
    # application.
    module InstanceMethods
      # Returns the repository objects configured for the application.
      def repositories
        opts[:repositories]
      end

      # Stores the file contained in a multipart POST +request+ in the
      # #repositories that will handle the mediatype of the file.
      def store(request)
        stored = repositories.each_with_object({}) do |repo, paths|
          next unless repo.supports? request.file_type

          paths[repo.name] = repo.store request.file
        end
        request.unsupported_media_type if stored.empty?
        stored
      end
    end

    # Includes methods to facilitate work with a file contained in a multipart
    # POST request.
    module RequestMethods
      # Returns the actual file (tempfile) for the request.
      #
      # ===== Options:
      #
      # * <tt>:property</tt> - name of the parameter property that contains the
      #   file.
      def file(property: 'file')
        params.dig property, :tempfile
      end

      # Returns the filename for the file contained in the request.
      #
      # ===== Options:
      #
      # * <tt>:property</tt> - name of the parameter property that contains the
      #   file.
      def filename(property: 'file')
        params.dig property, :filename
      end

      # Returns the media type for the file contained in the request.
      #
      # ===== Options:
      #
      # * <tt>:property</tt> - name of the parameter property that contains the
      #   file.
      def file_type(property: 'file')
        params.dig property, :type
      end

      # Halts the request with details about the media type. To be called when
      # the #file_type is not supported.
      def unsupported_media_type
        msg = "Image format #{file_type} is not supported."\
              " Supported formats are: #{roda_class.supported_media_types}."
        halt [333, { 'Content-Type' => 'text/html' }, [msg]]
      end
    end
  end
end
