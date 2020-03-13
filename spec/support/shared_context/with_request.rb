# frozen_string_literal: true

require_relative '../helpers/mockable'

RSpec.shared_context 'with request', shared_context: :metadata do
  def self.respond_and_log(verb, route)
    before do
      rack_env['HTTP_AUTHORIZATION'] = auth_header.join(':') if auth_header
    end

    it_behaves_like 'a rack app', verb, route, :not_to
    it_behaves_like 'a logger', verb, route, :<<
  end

  # ===== Authentication
  let(:key) { 'testkey' }
  let(:secret) { 'testsecret' }
  let(:hmac) { signature file, timestamp(now), username }

  # ===== Request Headers
  let(:rack_env) { { 'CONTENT_TYPE' => 'multipart/form-data' } }
  let(:auth_header) { [key, hmac] }

  # ===== Request Body
  let(:username) { 'UserName' }
  
  let :body do
    {
      specify_user: username,
      filename: filename,
      timestamp: timestamp(now),
      file: rackfile,
      is_public: false
    }
  end

  # ===== Response
  let(:bad_request_msg) { '{"message":"Bad request. Ignored."}' }
  let(:forbidden_msg) { '{"message":"Forbidden!"}' }

  let :capture_device do
    'Ihagee, EXAKTA Varex IIB, Carl Zeiss Jena Pancolar 2/50'
  end

  let(:checksum) { 'checksum' }
  let(:copyright) { 'The photographer' }
  let(:create_date) { '2020-03-06 00:00:00.000000' }
  let(:date_imaged) { '1976-05-27T00:00:00.000Z' }
  let(:mime) { 'image/jpeg' }
  let(:store_path) { 'path/to/stored_file.jpg' }
  let(:store_id) { 'stored_file' }

  let :asset_attributes do
    { asset_id: store_id,
      identifier: store_path,
      copies: [{ repository: backup_repo,
                 uri: 'path/to/backed_up_file.jpg' }],
      file_metadata_sets: Mockable.file_metadata,
      filename: filename,
      md5sum: checksum,
      media_type: mime,
      public: false,
      repository: store_repo }
  end

  let :response_body do
    { asset_identifier: store_id,
      resource_identifier: store_path,
      mime_type: mime,
      capture_device: capture_device,
      file_created_date: create_date,
      date_imaged: date_imaged,
      copyright_holder: copyright,
      checksum: checksum }.to_json
  end

  let(:success) { 'Success!' }

  # ===== Mocks
  let(:logger) { instance_spy 'Logger' }
end
