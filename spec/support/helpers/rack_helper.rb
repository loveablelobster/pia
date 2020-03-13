# frozen_string_literal: true

require 'rack/test'
require 'roda'
require 'pry-byebug'
require 'openssl'

ENV['RACK_ENV'] = 'test'
ENV['pia_key'] = 'testkey'
ENV['pia_secret'] = 'testsecret'

Mongoid.load! File.expand_path('config/mongoid.yaml'), :test

module Rackable
  include Rack::Test::Methods

  def _app(&block)
    c = Class.new Roda
    c.class_eval(&block)
    c
  end

  def signature(file, time, user = nil)
    filename = user ? File.basename(file) : file
    msg = [filename, user, time].compact
    msg.push Digest::MD5.file(file).hexdigest if user
    OpenSSL::HMAC.hexdigest 'SHA256', 'testsecret', msg.join('|')
  end

  def timestamp(time)
    time.strftime '%Y-%m-%d %H:%M:%S.%6L %Z'
  end
end

TESTDIR = 'spec/support/test_files'
IMGSTORE = File.join TESTDIR, 'imgstore'
DOCSTORE = File.join TESTDIR, 'docstore'
WORKDIR = File.join TESTDIR, 'workdir'
LIBDIR = File.join TESTDIR, 'custom_libs'

[WORKDIR, IMGSTORE, DOCSTORE].each do |dir|
  FileUtils.mkdir dir unless File.exist? dir
end

RSpec.configure do |config|
  config.include Rackable

  config.before(:suite) do
    [WORKDIR, IMGSTORE, DOCSTORE].each do |dir|
      FileUtils.mkdir dir unless File.exist? dir
    end
  end

  config.after(:each) do
    [IMGSTORE, DOCSTORE].each do |dir|
      link = File.join(dir, '.current_store_path')
      FileUtils.rm link if File.exists? link
      Dir.glob(File.join(dir, '*')).each do |subdir|
        FileUtils.rm_r subdir
      end
    end
  end

  config.after(:suite) do
    Repository.destroy_all
    [WORKDIR, IMGSTORE, DOCSTORE].each do |dir|
      FileUtils.rm_r dir if File.exist? dir
    end
  end
end

require_relative '../../../lib/pia'
require_relative '../shared_context/with_files'
require_relative '../shared_context/with_mocks'
require_relative '../shared_context/with_request'
require_relative '../shared_context/with_time'
require_relative '../shared_examples/for_logging'
require_relative '../shared_examples/for_requests'
