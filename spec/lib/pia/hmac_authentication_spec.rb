# frozen_string_literal: true

RSpec.describe Pia::HmacAuthentication do
  include_context 'with files'
  include_context 'with request'
  include_context 'with time'

  let :app do
    _app do
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
  
  before do
    app.opts[:common_logger] = logger
    rack_env['HTTP_AUTHORIZATION'] = auth_header.join(':')
  end

  context 'when posting to upload' do
    context 'with valid signature, data, and file' do
      it_behaves_like 'a rack app', :post, '/', :to do
        let(:message) { 'authenticated' }
        let(:status) { 200 }
      end
    end

    context 'with invalid header, data, or file' do
      context 'without a file' do
        before { body.delete :file }

        let(:message) { bad_request_msg }
        let(:status) { 111 }
        let(:log_msg) { start_with 'Request aborted. Missing element: file.' }

        it_behaves_like 'a rack app', :post, '/', :not_to
        it_behaves_like 'a logger', :post, '/', :warn
      end

      context 'without filename' do
        before { body.delete :filename }

        let(:message) { bad_request_msg }
        let(:status) { 111 }

        let :log_msg do
          start_with 'Request aborted. Missing element: filename.'
        end

        it_behaves_like 'a rack app', :post, '/', :not_to
        it_behaves_like 'a logger', :post, '/', :warn
      end

      context 'without timestamp' do
        before { body.delete :timestamp }

        let(:message) { bad_request_msg }
        let(:status) { 111 }

        let :log_msg do
          start_with 'Request aborted. Missing element: timestamp.'
        end

        it_behaves_like 'a rack app', :post, '/', :not_to
        it_behaves_like 'a logger', :post, '/', :warn
      end

      context 'without username' do
        before { body.delete :specify_user }

        let(:message) { bad_request_msg }
        let(:status) { 111 }

        let :log_msg do
          start_with 'Request aborted. Missing element: specify_user.'
        end

        it_behaves_like 'a rack app', :post, '/', :not_to
        it_behaves_like 'a logger', :post, '/', :warn
      end

      context 'without an HTTP_AUTHORIZATION header' do
        before { rack_env.delete 'HTTP_AUTHORIZATION' }

        let(:message) { forbidden_msg }
        let(:status) { 403 }

        let :log_msg do
          start_with 'Attempt to upload file without HTTP_AUTHORIZATION header'
        end
        
        it_behaves_like 'a rack app', :post, '/', :not_to
        it_behaves_like 'a logger', :post, '/', :warn
      end

      context 'with a bad checksum'
      context 'with an invalid HTTP_AUTHORIZATION header'
      context 'with a bad key'
    end
  end
end
