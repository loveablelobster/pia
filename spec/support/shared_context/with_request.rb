# frozen_string_literal: true

RSpec.shared_context 'with request', shared_context: :metadata do
  # ===== Authentication
  let(:key) { 'testkey' }
  let(:secret) { 'testsecret' }

  # ===== Files
  let(:file) { 'spec/support/test_files/example.jpg' }
  let(:filename) { File.basename file }
  let(:rackfile) { Rack::Test::UploadedFile.new file, 'image/jpeg' }

  # ===== Request Headers
  let(:rack_env) { { 'CONTENT_TYPE' => 'multipart/form-data' } }
  let(:auth_header) { [key] }

  # ===== Request Body
  let(:username) { 'UserName' }
  
  let :body do
    {
      specify_user: username,
      filename: filename,
      timestamp: timestamp(now),
      file: rackfile
    }
  end

  # ===== Response
  let(:bad_request_msg) { '{"message":"Bad request. Ignored."}' }
  let(:forbidden_msg) { '{"message":"Forbidden!"}' }

  # ===== Mocks
  let(:success) { 'Success!' }
  
  let(:logger) { instance_spy 'Logger' }
end
