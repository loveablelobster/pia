# frozen_string_literal: true

RSpec.describe Pia::HmacAuthentication do
  include_context 'with files'
  include_context 'with request'
  include_context 'with time'

  let :app do
    _app do
      plugin Pia::Logger
      plugin Pia::HmacAuthentication,
             hmac_key: 'testkey',
             hmac_secret: 'testsecret',
             hmac_separator: '|',
             hmac_hash_function: 'SHA256'
      route do |r|
        r.on do
          r.authenticate_upload
          'authenticated'
        end
      end
    end
  end

  def self.respond_and_log(verb, route)
    before do
      rack_env['HTTP_AUTHORIZATION'] = auth_header.join(':') if auth_header
    end

    it_behaves_like 'a rack app', verb, route, :not_to
    it_behaves_like 'a logger', verb, route, :<<
  end

  before do
    app.opts[:common_logger] = logger
  end

  context 'when posting to upload' do
    context 'with valid signature, data, and file' do
      before do
        rack_env['HTTP_AUTHORIZATION'] = auth_header.join(':')
      end

      it_behaves_like 'a rack app', :post, '/', :to do
        let(:message) { 'authenticated' }
        let(:status) { 200 }
      end
    end

    context 'without a file' do
      before { body.delete :file }

      let(:message) { bad_request_msg }
      let(:status) { 111 }
      let(:log_msg) { start_with 'Request aborted. Missing element: file.' }

      respond_and_log :post, '/'
    end

    context 'without filename' do
      before { body.delete :filename }

      let(:message) { bad_request_msg }
      let(:status) { 111 }

      let :log_msg do
        start_with 'Request aborted. Missing element: filename.'
      end

      respond_and_log :post, '/'
    end

    context 'without timestamp' do
      before { body.delete :timestamp }

      let(:message) { bad_request_msg }
      let(:status) { 111 }

      let :log_msg do
        start_with 'Request aborted. Missing element: timestamp.'
      end

      respond_and_log :post, '/'
    end

    context 'without username' do
      before { body.delete :specify_user }

      let(:message) { bad_request_msg }
      let(:status) { 111 }

      let :log_msg do
        start_with 'Request aborted. Missing element: specify_user.'
      end

      respond_and_log :post, '/'
    end

    context 'without an HTTP_AUTHORIZATION header' do
      let(:auth_header) { nil }
      let(:message) { forbidden_msg }
      let(:status) { 403 }

      let :log_msg do
        start_with 'Attempt to upload file without HTTP_AUTHORIZATION header'
      end

      respond_and_log :post, '/'
    end

    context 'with a missing auth key' do
      let(:auth_header) { ['', hmac] }
      let(:message) { forbidden_msg }
      let(:status) { 401 }

      let :log_msg do
        start_with 'Attempt to upload file with an invalid'\
          ' HTTP_AUTHORIZATION header'
      end

      respond_and_log :post, '/'
    end

    context 'with a missing signature' do
      let(:auth_header) { [key] }
      let(:message) { forbidden_msg }
      let(:status) { 401 }

      let :log_msg do
        start_with 'Attempt to upload file with an invalid'\
          ' HTTP_AUTHORIZATION header'
      end

      respond_and_log :post, '/'
    end

    context 'with a bad key' do
      let(:auth_header) { ['foo', hmac] }
      let(:message) { forbidden_msg }
      let(:status) { 401 }

      let :log_msg do
        start_with 'Attempt to upload file with an unknown API Key: foo'
      end

      respond_and_log :post, '/'
    end

    context 'with a bad signature' do
      let(:auth_header) { [key, 'bar'] }
      let(:message) { forbidden_msg }
      let(:status) { 401 }

      let :log_msg do
        start_with 'Attempt to upload file with a bad HMAC signature.'
      end

      respond_and_log :post, '/'
    end
  end
end
