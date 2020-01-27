# frozen_string_literal: true

RSpec.describe Pia::HmacAuthentication do
  include_context 'with request'
  include_context 'wtih time'

  let :app do
    _app do
      plugin Pia::HmacAuthentication
      route do |r|
        r.on do
          r.authenticate_upload
          'authenticated'
        end
      end
    end
  end
  
  before { app.opts[:common_logger] = logger }

  context 'when posting to upload' do
    context 'with valid signature, data, and file' do
      it_behaves_like 'a rack app', :post, '/', :to do
        let(:message) { 'authenticated' }
        let(:status) { 200 }
      end
    end

    context 'with invalid header, data, or file' do
      context 'without a file' do
        let(:message) { bad_request_msg }
        let(:status) { 111 }

        let(:log_msg) { start_with 'Request aborted. No file supplied.' }

        it_behaves_like 'a rack app', :post, '/', :not_to
        ti_behaves_like 'a logger', :post, '/', :warn
      end

      context 'without filename'
      context 'without username'
      context 'with a bad checksum'
      context 'without HTTP_AUTHORIZATION header'
      context 'with an invalid HTTP_AUTHORIZATION header'
      context 'with a bad key'
    end
  end
end
