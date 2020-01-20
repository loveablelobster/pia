# frozen_string_literal: true

RSpec.describe Pia::Pia do
  include_context 'with request'

  subject { last_response }

  let(:key) { 'testkey' }
  let(:auth_header) { [key] }
  # FIXME: duplication, also used in spec/support/helpers/rack...

  let(:rackfile) { Rack::Test::UploadedFile.new file, 'image/jpeg' }
  let(:jp2file) { 'spec/support/test_files/example.jp2' }
  let(:rackjp2file) { Rack::Test::UploadedFile.new jp2file, 'image/jp2' }

  describe 'GET /' do
    before { get '/' }

    it { is_expected.to be_ok }
  end

  describe 'POST asset/upload' do
    before do
      auth_header[1] = signature file, timestamp(now), username
      rack_env['HTTP_AUTHORIZATION'] = auth_header.join(':')
      post '/asset/upload/', body, rack_env
    end

    context 'when the request is valid' do
      it { is_expected.to be_ok }

      it 'creates an asset'

      it 'returns JSON'
    end

    context 'when request is from an unknown host' do
      before { env 'REMOTE_ADDR', '123.123.123.123' }

      let(:message) { '' }
      let(:status) { 403 }

      it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
    end

    context 'with invalid timestamp' do
      before { body.delete :timestamp }

      let(:message) { '{"message":"Bad request. Ignored."}' }
      let(:status) { 111 }

      context 'when it is missing' do
        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
      end

      context 'when it is expired' do
        before { body[:timestamp] = timestamp two_hours_ago }

        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
      end

      context 'when it is fudged (in the future)' do
        before { body[:timestamp] = timestamp two_hours_ahead }

        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
      end
    end

    context 'without all required data' do
      let(:message) { '{"message":"Bad request. Ignored."}' }
      let(:status) { 111 }
      
      context 'when filename is missing' do
        before { body.delete :filename }

        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
      end

      context 'when user name is missing' do
        before { body.delete :specify_user }

        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
      end
    end

    context 'with a bad HMAC signature' do
      before do
        body[:filename] = 'inappropriate.jpg'
        body[:specify_user] = 'NotAUser'
      end

      let(:message) { '{"message":"Forbidden!"}' }
      let(:status) { 403 }

      it_behaves_like 'a rack app', :post, '/asset/upload', :not_to
    end

    context 'with an unsupported file type' do
      before do
        body[:filename] = File.basename(jp2file)
        auth_header[1] = signature jp2file, timestamp(now), username
        rack_env['HTTP_AUTHORIZATION'] = auth_header.join(':')
        body[:file] = rackjp2file
      end

      let :message do
        '{"message":"Image format image/jp2 is not supported. Supported'\
        ' formats are [\"image/jpeg\", \"image/tiff\", \"image/png\"]"}'
      end

      let(:status) { 333 }

      it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
    end
  end

  describe 'GET asset/:id/fullsize'

  describe 'GET asset/:id/thumbnail'

  describe 'GET asset/:id/:region/:size/:rotation/:quality.:format'

  describe 'DELETE asset/:id/delete'
end
