# frozen_string_literal: true

module Pia
  module RepositoryStack
    # Default path for the configuration file.
    REPOSITORY_CONFIG = 'config/repositories.yaml'

    # RepositoryStack objects configure a stack of repositories for file
    # storage.
    #
    # A repository must be an object that responds to <tt>:media_types</tt>,
    # <tt>:name</tt>, <tt>:store</tt>, and <tt>:supports?</tt>. The interface is
    # implemented by Repository, which serves as the default class for
    # repository objects. Refer to that class for details on method signature
    # and return values.
    #
    # A RepositoryStack is normally initialized with a path to a YAML file, that
    # must contain keys for the #workdir and #repositories. It can contain a key
    # for #libs.
    #
    # ===== Example
    #
    #   ---
    #   workdir: /var/workdir
    #   libs:
    #     - /etc/pia/libs
    #   repositories:
    #     -
    #       name: Storage
    #       storage_directory: /var/www
    #
    # If no path to a config file is passed, the constructor will try to locate
    # a file in the relative given by the REPOSITORY_CONFIG constant.
    #
    # Each hash given in the <tt>repositories</tt> collection must contain any
    # options required to properly initialize the repository class in question.
    # If a class other than Repository is to be used, provide the
    # <tt>repository_class</tt> property and as value give the class name in
    # underscore notation (e.g. <tt>custom_store</tt> for the class
    # +CustomStore+. The initializer will try to locate the source file
    # containing the class definition in the array of source #libs and require
    # it. The source file must be named according to the vaule given for
    # <tt>repository_class</tt> with the <tt>.rb</tt> extension.
    class RepositoryStack
      # Array of paths to directories that contain source files for custom file
      # repositories or file operations.
      attr_accessor :libs

      # Directory where temporary files are written during file processing.
      attr_accessor :workdir

      # Set of repositories objects.
      attr_reader :repositories

      # Default path where the constructor will look for the config file.
      def self.default_config_path
        File.join Dir.pwd, REPOSITORY_CONFIG
      end

      # Loads and parses the YAML +file+ and returns its contents as a Hash.
      def self.load(file)
        return unless file || File.exist?(default_config_path)

        Psych.load_file(file || config).transform_keys(&:to_sym)
      end

      # Returns a new instance.
      #
      # +config+ is the path to a YAML file containing the configuration. If no
      # path is given, the constructor will look in the .default_config_path.
      def initialize(config = nil)
        config = RepositoryStack.load config
        @libs = config&.fetch(:libs, [])
        @libs.each { |lib| FilePipeline << lib }
        @repositories = Set.new
        @workdir = config&.fetch :workdir, nil
        load_repositories config&.fetch(:repositories, nil)
        yield self if block_given?
      end

      # Adds +repository+ to the set of #repositories of +self+.
      def <<(repository)
        repositories << repository
      end

      private

      # Creates a new repository for each item in +config+ (an Array of Hashes)
      # and adds it to #repositories.
      def load_repositories(config)
        return unless config

        config.each do |repo|
          repo.transform_keys!(&:to_sym)
          self << make_repository(repo)
        end
      end

      # Creates a new repository initialized according to <tt>repo_config</tt>
      # (a Hash).
      def make_repository(repo_config)
        repo_class = repository_class repo_config.delete(:repository_class)
        repo_class.new self, **repo_config
      end

      # Returns the repository class defined in <tt>src_file</tt> (a file
      # basename without extension).
      #
      # Returns the Repository class if <tt>src_file</tt> is +nil+.
      def repository_class(src_file)
        return Repository unless src_file

        const = src_file.split('_').map(&:capitalize).join
        src_file += '.rb' unless src_file.end_with? '.rb'
        lib = libs.find { |dir| Dir.children(dir).include? src_file }
        src_file = File.join lib, src_file
        require File.expand_path(src_file)
        Module.const_get const
      end
    end
  end
end
