# frozen_string_literal: true

require_relative '../pia'

RSpec.describe PiaApp do
  include_context 'with files'
  include_context 'with request'
  include_context 'with time'

  subject { last_response }

  before { app.opts[:common_logger] = logger }

  let(:app) { described_class }
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
    end

    context 'when the request is valid' do
      before { Asset.destroy_all }

      let :response_body do
        { asset_identifier: 'stored_file',
          resource_identifier: 'path/to/stored_file.jpg',
          mime_type: 'image/jpeg',
          capture_device: 'Ihagee, EXAKTA Varex IIB, Carl Zeiss Jena Pancolar 2/50',
          file_created_date: '2020-03-06 00:00:00.000000',
          date_imaged: '1976-05-27T00:00:00.000Z',
          copyright_holder: 'The photographer',
          checksum: 'checksum' }.to_json
      end

      it do
        post 'asset/upload/', body, rack_env
        expect(last_response).to be_ok
      end

      it 'creates an asset' do
        expect { post 'asset/upload/', body, rack_env }
          .to change(Asset, :all)
          .from(be_empty)
          .to include a_kind_of(Asset)
      end

      it 'returns JSON' do
        post 'asset/upload/', body, rack_env
        expect(last_response.body).to eq response_body
      end
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
        let(:log_msg) { "Request aborted. #{missing_timestamp}" }

        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
        it_behaves_like 'a logger', :post, '/asset/upload/', :warn
      end

      context 'when it is expired' do
        before { body[:timestamp] = timestamp two_hours_ago }

        let(:log_msg) { start_with "Request aborted. #{expired_timestamp}" }

        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
        it_behaves_like 'a logger', :post, '/asset/upload/', :warn
      end

      context 'when it is fudged (in the future)' do
        before { body[:timestamp] = timestamp two_hours_ahead }

        let(:log_msg) { start_with "Request aborted. #{future_timestamp}" }

        it_behaves_like 'a rack app', :post, '/asset/upload/', :not_to
        it_behaves_like 'a logger', :post, '/asset/upload/', :warn
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
      let(:status) { 401 }

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
        'Image format image/jp2 is not supported. Supported formats are:'\
        ' ["image/jpeg", "image/tiff"].'
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
