# frozen_string_literal: true

require 'rack/test'
require 'pry-byebug'

require 'openssl'

ENV['RACK_ENV'] = 'test'

module Rackable
  include Rack::Test::Methods

  def app
    described_class
  end

  def signature(file, time, user = nil)
    filename = user ? File.basename(file) : file
    msg = [filename, user, time].compact
    msg.push Digest::MD5.file(file).hexdigest if user
    OpenSSL::HMAC.hexdigest 'SHA512', 'testwhatever', msg.join("\n")
  end

  def timestamp(time)
    time.utc.strftime '%Y-%m-%d %H:%M:%S.%6L'
  end
end

RSpec.configure do |config|
  config.include Rackable
end

require_relative '../../../pia'
require_relative '../shared_examples/for_requests'
